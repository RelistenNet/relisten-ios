//
//  ArtistViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 3/7/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import KASlideShow
import AsyncDisplayKit
import RealmSwift

public class ArtistViewController : RelistenTableViewController<[Year]>, KASlideShowDataSource, UIViewControllerRestoration {
    public let artist: ArtistWithCounts
    private var years: [Year] = []

    lazy var settingsViewController : SettingsViewController = {
        return SettingsViewController()
    }()

    public required init(artist: ArtistWithCounts) {
        self.artist = artist
        
        super.init(useCache: true, refreshOnAppear: true)
        
        self.restorationIdentifier = "net.relisten.ArtistViewController.\(artist.slug)"
        self.restorationClass = ArtistViewController.self
        
        if RelistenApp.sharedApp.isPhishOD {
            let settingsItem = UIBarButtonItem(image: #imageLiteral(resourceName: "gear"), style: .plain, target: self, action: #selector(presentSettings(_:)))
            self.navigationItem.rightBarButtonItem = settingsItem
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported...like at all.")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style) {
        fatalError("init(useCache:refreshOnAppear:style:) has not been implemented")
    }
    
    @objc func presentSettings(_ sender: UINavigationBar?) {
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    private var av: RelistenMenuView! = nil
    public override func viewDidLoad() {
        if artist.name == "Phish" {
            AppColors_SwitchToPhishOD()
        }
        else {
            AppColors_SwitchToRelisten()
        }
        
        navigationItem.largeTitleDisplayMode = .always

        super.viewDidLoad()

        tableNode.view.separatorStyle = .none
        
        if RelistenApp.sharedApp.isPhishOD {
            title = RelistenApp.appName
        } else {
            title = artist.name
        }
        
        av = RelistenMenuView(artist: artist, inViewController: self)
        av.frame.origin = CGPoint(x: 0, y: 16)
        av.frame.size = av.sizeThatFits(CGSize(width: tableNode.view.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
        
        let containerView = UIView(frame: av.frame.insetBy(dx: 0, dy: -48).insetBy(dx: 0, dy: 16))
        containerView.addSubview(av)

        tableNode.view.tableHeaderView = containerView
        
        setupBackgroundSlideshow()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewDidAppear_SlideShow(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewWillDisappear_SlideShow(animated)
    }
    
    // recently played by band
    // recently played by user
    // recently added
    
    var shuffledImageNames: [NSString] = []
    var slider: KASlideShow! = nil
    
    public override var resource: Resource? { get { return api.years(byArtist: artist) } }
    
    public override func dataChanged(_ data: [Year]) {
        years = sortedYears(from: data, for: artist)
        super.dataChanged(data)
    }
    
    public override func has(oldData: [Year], changed: [Year]) -> Bool {
        return oldData.count != changed.count
    }
    
    override public func numberOfSections(in tableNode: ASTableNode) -> Int {
        return years.count > 0 ? 1 : 0
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return years.count
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let year = years[indexPath.row]
        
        return { YearNode(year: year) }
    }
    
    override public func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        let vc = YearViewController(artist: artist, year: years[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return years.count > 0 ? "\(years.count) \(years.count > 1 ? "Years" : "Year")" : nil
    }
    
    enum CodingKeys: String, CodingKey {
        case artist = "artist"
    }
    
    static public func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        // Decode the artist object from the archive and init a new artist view controller with it
        do {
            if let artistData = coder.decodeObject(forKey: CodingKeys.artist.rawValue) as? Data {
                let encodedArtist = try JSONDecoder().decode(ArtistWithCounts.self, from: artistData)
                let vc = ArtistViewController(artist: encodedArtist)
                return vc
            }
        } catch { }
        return nil
    }
    
    override public func encodeRestorableState(with coder: NSCoder) {
        // Encode the artist object so we can re-create an ArtistViewController after state restoration
        super.encodeRestorableState(with: coder)
        
        do {
            let artistData = try JSONEncoder().encode(self.artist)
            coder.encode(artistData, forKey: CodingKeys.artist.rawValue)
        } catch { }
    }
    
    override public func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }

    // MARK: Phish Slideshow
    public func slideShow(_ slideShow: KASlideShow!, objectAt index: UInt) -> NSObject! {
        return shuffledImageNames[Int(index)]
    }
    
    public func slideShowImagesNumber(_ slideShow: KASlideShow!) -> UInt {
        return artist.name == "Phish" ? 36 : 0
    }
    
    public func setupBackgroundSlideshow() {
        guard artist.name == "Phish - disabled" else {
            return
        }
        
        for i in 1...36 {
            shuffledImageNames.append(NSString(string: "phishod_bg_" + (i < 10 ? "0" : "") + String(i)))
        }
        
        shuffledImageNames.shuffle()
        
        slider = KASlideShow(frame: view.bounds)
        
        slider.datasource = self
        slider.imagesContentMode = .scaleAspectFill
        slider.delay = 7.5
        slider.transitionDuration = 1.0
        slider.transitionType = .fade
        
        slider.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        tableNode.view.backgroundView = slider
//        
        let fog = UIView(frame: view.bounds)
        fog.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        fog.backgroundColor = UIColor.blue.withAlphaComponent(0.4)
        
        slider.addSubview(fog)
        
        tableNode.backgroundColor = UIColor.clear
    }
    
    public func viewWillDisappear_SlideShow(_ animated: Bool) {
        if let s = slider {
            s.stop()
        }
    }
    
    public func viewDidAppear_SlideShow(_ animated: Bool) {
        if let s = slider {
            s.start()
        }
    }
}

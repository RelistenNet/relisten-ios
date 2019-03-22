//
//  YearsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit

import Siesta
import AsyncDisplayKit
import SINQ

public class YearsViewController: RelistenTableViewController<[Year]>, UIViewControllerRestoration {
    
    private let artist: Artist
    private var years: [Year] = []
    
    public required init(artist: Artist, years: [Year]? = nil) {
        self.artist = artist
        if let years = years {
            self.years = years
        }
        
        super.init(useCache: true, refreshOnAppear: true)
        
        self.restorationIdentifier = "net.relisten.YearsViewController.\(artist.slug)"
        self.restorationClass = YearsViewController.self
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Years"
    }
    
    public override var resource: Resource? { get { return api.years(byArtist: artist) } }
    
    public override func dataChanged(_ data: [Year]) {
        years = sortedYears(from: data, for: artist)
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
    
    //MARK: State restoration
    enum CodingKeys: String, CodingKey {
        case artist = "artist"
        case years = "years"
    }
    
    static public func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        do {
            if let artistData = coder.decodeObject(forKey: CodingKeys.artist.rawValue) as? Data {
                let encodedArtist = try JSONDecoder().decode(Artist.self, from: artistData)
                var encodedYears : [Year]? = nil
                if let yearsData = coder.decodeObject(forKey: CodingKeys.years.rawValue) as? Data {
                    encodedYears = try JSONDecoder().decode([Year].self, from: yearsData)
                }
                let vc = YearsViewController(artist: encodedArtist, years: encodedYears)
                return vc
            }
        } catch { }
        return nil
    }
    
    override public func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        do {
            let artistData = try JSONEncoder().encode(self.artist)
            coder.encode(artistData, forKey: CodingKeys.artist.rawValue)
            
            let encodedYears = try JSONEncoder().encode(self.years)
            coder.encode(encodedYears, forKey: CodingKeys.years.rawValue)
        } catch { }
    }
    
    override public func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }
}

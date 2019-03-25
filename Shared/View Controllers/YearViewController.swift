//
//  YearViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import UIKit
import Siesta
import AsyncDisplayKit

public class YearViewController: ShowListViewController<YearWithShows>, UIViewControllerRestoration {
    let year: Year
    
    public required init(artist: Artist, year: Year) {
        self.year = year
        
        super.init(artist: artist, tourSections: true)
        
        self.restorationIdentifier = "net.relisten.ShowListViewController.\(String(describing: self))"
        self.restorationClass = type(of: self)
        
        title = year.year
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(artist: SlimArtistWithFeatures, tourSections: Bool, enableSearch: Bool) {
        fatalError("init(artist:showsResource:tourSections:) has not been implemented")
    }
    
    public override var resource: Resource? {
        get {
            return RelistenApi.shows(inYear: year, byArtist: artist)
        }
    }
    
    public override func has(oldData old: YearWithShows, changed new: YearWithShows) -> Bool {
        return old.shows.count != new.shows.count || old.year != new.year
    }
    
    public override func extractShowsAndSource(forData: YearWithShows) -> [ShowWithSingleSource] {
        return forData.shows.map({ ShowWithSingleSource(show: $0, source: nil, artist: artist) })
    }
    
    // This is silly. Texture can't figure out that our subclass implements this method due to some shenanigans with generics and the swift/obj-c bridge, so we have to do this.
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
    
    //MARK: State Restoration
    enum CodingKeys: String, CodingKey {
        case year = "year"
    }
    static public func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        // Decode the artist object from the archive and init a new artist view controller with it
        do {
            if let artistData = coder.decodeObject(forKey: ShowListViewController<YearWithShows>.CodingKeys.artist.rawValue) as? Data,
               let yearData = coder.decodeObject(forKey: CodingKeys.year.rawValue) as? Data {
                let encodedArtist = try JSONDecoder().decode(Artist.self, from: artistData)
                let encodedYear = try JSONDecoder().decode(Year.self, from: yearData)
                let vc = YearViewController(artist: encodedArtist, year: encodedYear)
                return vc
            }
        } catch { }
        return nil
    }
    
    override public func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        do {
            let encodedYear = try JSONEncoder().encode(self.year)
            coder.encode(encodedYear, forKey: CodingKeys.year.rawValue)
        } catch { }
    }
    
    override public func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }
}

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

public class YearViewController: ShowListViewController<YearWithShows> {
    let year: Year
    
    public required init(artist: ArtistWithCounts, year: Year) {
        self.year = year
        
        super.init(artist: artist, showsResource: RelistenApi.shows(inYear: year, byArtist: artist), tourSections: true)
        
        title = year.year
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(artist: SlimArtistWithFeatures, showsResource: Resource?, tourSections: Bool) {
        fatalError("init(artist:showsResource:tourSections:) has not been implemented")
    }
    
    public override func extractShowsAndSource(forData: YearWithShows) -> [ShowWithSingleSource] {
        return forData.shows.map({ ShowWithSingleSource(show: $0, source: nil) })
    }
    
    // This subclass has to re-implement this method because Texture tries to perform an Obj-C respondsToSelctor: check and it's not finding the methods if they just exist on the superclass with the argument label names (numberOfSectionsIn: does exist though)
    public override func numberOfSections(in tableNode: ASTableNode) -> Int {
        return super.numberOfSections(in: tableNode)
    }
    
    public override func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return super.tableNode(tableNode, numberOfRowsInSection: section)
    }
    
    public override func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return super.tableNode(tableNode, nodeBlockForRowAt: indexPath)
    }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return super.tableView(tableView, titleForHeaderInSection: section)
    }
    
    public override func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        return super.tableNode(tableNode, didSelectRowAt: indexPath)
    }
}

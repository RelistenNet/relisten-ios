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

public class YearsViewController: RelistenTableViewController<[Year]> {
    
    private let artist: ArtistWithCounts
    private var years: [Year] = []
    
    public required init(artist: ArtistWithCounts) {
        self.artist = artist
        
        super.init(useCache: true, refreshOnAppear: true)
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
}

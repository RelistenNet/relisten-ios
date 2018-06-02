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

class YearsViewController: RelistenAsyncTableController<[Year]> {
    
    let artist: ArtistWithCounts
    var years: [Year] = []
    
    public required init(artist: ArtistWithCounts) {
        self.artist = artist
        
        super.init(useCache: true, refreshOnAppear: true)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Years"
    }
    
    override var resource: Resource? { get { return api.years(byArtist: artist) } }
    
    override func dataChanged(_ data: [Year]) {
        years = data
    }
    
    override func has(oldData: [Year], changed: [Year]) -> Bool {
        return oldData.count != changed.count
    }
    
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return years.count > 0 ? 1 : 0
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return years.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let year = years[indexPath.row]
        
        return { YearNode(year: year) }
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        let vc = YearViewController(artist: artist, year: years[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
}

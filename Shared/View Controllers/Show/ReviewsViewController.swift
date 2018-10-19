//
//  ReviewsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import AsyncDisplayKit
import SafariServices
import Siesta

public class ReviewsViewController : RelistenTableViewController<[SourceReview]> {
    let source: SourceFull
    let artist: Artist
    var reviews: [SourceReview] = []
    
    public required init(reviewsForSource source: SourceFull, byArtist artist: Artist) {
        self.source = source
        self.artist = artist
        
        super.init(useCache: true, refreshOnAppear: true)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = source.review_count.pluralize("Review", "Reviews")
    }
    
    open override var resource: Resource? { get { return api.reviews(forSource: source, byArtist: artist) } }
    
    public override func dataChanged(_ data: [SourceReview]) {
        reviews = data
    }
    
    override public func numberOfSections(in tableNode: ASTableNode) -> Int {
        return 1
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }
    
    override public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        guard indexPath.row >= 0, indexPath.row < reviews.count else {
            return { ASCellNode() }
        }
        
        let review = reviews[indexPath.row]
        return { ReviewCellNode(review: review, forArtist: self.artist) }
    }
    
    func tableNode(_ tableNode: ASTableNode, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

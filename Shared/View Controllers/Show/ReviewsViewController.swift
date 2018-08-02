//
//  ReviewsViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import SafariServices
import Siesta

public class ReviewsViewController : RelistenTableViewController<[SourceReview]> {
    let source: SourceFull
    let artist: ArtistWithCounts
    
    public required init(reviewsForSource source: SourceFull, byArtist artist: ArtistWithCounts) {
        self.source = source
        self.artist = artist
        
        super.init(useCache: true, refreshOnAppear: false)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Review".pluralize(source.review_count)
        cellDefaultBackgroundColor = UIColor.white
    }
    
    open override var resource: Resource? { get { return api.reviews(forSource: source, byArtist: artist) } }
    
    public override func render(forData: [SourceReview]) {
        layout {
            return self.buildLayout(forData)
        }
    }
    
    public func buildLayout(_ reviews: [SourceReview]) -> [Section<[Layout]>] {
        let reviewLayouts = reviews.map({ ReviewLayout(review: $0, forArtist: artist) })
        
        return [ LayoutsAsSingleSection(items: reviewLayouts) ]
    }
}

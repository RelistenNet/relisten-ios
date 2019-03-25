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

public class ReviewsViewController : RelistenTableViewController<[SourceReview]>, UIViewControllerRestoration {
    let source: SourceFull
    let artist: Artist
    var reviews: [SourceReview] = []
    
    public required init(reviewsForSource source: SourceFull, byArtist artist: Artist) {
        self.source = source
        self.artist = artist
        
        super.init(useCache: true, refreshOnAppear: true)
        
        self.restorationIdentifier = "net.relisten.ReviewsViewController.\(artist.slug).\(source.upstream_identifier)"
        self.restorationClass = type(of: self)
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
        super.dataChanged(data)
    }
    
    override public func numberOfSections(in tableNode: ASTableNode) -> Int {
        return 1
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        guard indexPath.row >= 0, indexPath.row < reviews.count else {
            return { ASCellNode() }
        }
        
        let review = reviews[indexPath.row]
        return { ReviewCellNode(review: review, forArtist: self.artist) }
    }
    
    func tableNode(_ tableNode: ASTableNode, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    //MARK: State Restoration
    enum CodingKeys: String, CodingKey {
        case artist = "artist"
        case source = "source"
        case reviews = "reviews"
    }
    
    static public func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        // Decode the artist object from the archive and init a new artist view controller with it
        do {
            if let artistData = coder.decodeObject(forKey: CodingKeys.artist.rawValue) as? Data,
               let sourceData = coder.decodeObject(forKey: CodingKeys.source.rawValue) as? Data {
                let encodedArtist = try JSONDecoder().decode(Artist.self, from: artistData)
                let encodedSource = try JSONDecoder().decode(SourceFull.self, from: sourceData)
                let vc = ReviewsViewController(reviewsForSource: encodedSource, byArtist: encodedArtist)
                
                if let reviewData = coder.decodeObject(forKey: CodingKeys.reviews.rawValue) as? Data,
                   let encodedReviews = try? JSONDecoder().decode([SourceReview].self, from: reviewData) {
                    vc.dataChanged(encodedReviews)
                }
                
                return vc
            }
        } catch { }
        return nil
    }
    
    override public func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        do {
            let encodedArtist = try JSONEncoder().encode(self.artist)
            coder.encode(encodedArtist, forKey: CodingKeys.artist.rawValue)
            
            let encodedSource = try JSONEncoder().encode(self.source)
            coder.encode(encodedSource, forKey: CodingKeys.source.rawValue)
            
            let encodedReviews = try JSONEncoder().encode(self.reviews)
            coder.encode(encodedReviews, forKey: CodingKeys.reviews.rawValue)
        } catch { }
    }
    
    override public func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }
}

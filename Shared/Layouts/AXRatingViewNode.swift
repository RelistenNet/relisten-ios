//
//  AXRatingViewNode.swift
//  Relisten
//
//  Created by Alec Gorge on 6/1/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit
import AXRatingView

public let RatingViewStubBounds = { () -> CGRect in
    let r = AXRatingView()
    r.isUserInteractionEnabled = false
    r.value = 0.5
    r.sizeToFit()
    
    return r.bounds
}()

public class AXRatingViewNode : ASDisplayNode {
    public let value: Float
    
    public init(value: Float) {
        self.value = value
        
        ratingViewNode = ASDisplayNode(viewBlock: {
            let a = AXRatingView()
            a.sizeToFit()
            return a
        })
        
        super.init()
        
        automaticallyManagesSubnodes = true
    }
    
    public let ratingViewNode: ASDisplayNode
    public var fixedSize = RatingViewStubBounds.size
    
    public override func didLoad() {
        if let ax = ratingViewNode.view as? AXRatingView {
            ax.isUserInteractionEnabled = false
            ax.value = value * 5.0
        }
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ratingViewNode.style.minSize = fixedSize
        
        let l = ASWrapperLayoutSpec(layoutElement: ratingViewNode)
        l.style.minSize = fixedSize
        
        return l
    }
}

//
//  FavoriteButtonNode.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/23/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import UIKit
import FaveButton
import Observable

open class FavoriteButtonNode : ASDisplayNode {
    public static let image = UIImage(named: "heart")
    
    open var currentlyFavorited: Bool = false
    
    open let faveButtonNode: ASDisplayNode
    
    open var disposal = Disposal()
    
    open var accessibilityLabelString = "Favorite"
    
    public override init() {
        faveButtonNode = ASDisplayNode(viewBlock: { FaveButton(frame: CGRect(x: 0, y: 0, width: 32, height: 32)) })
        
        super.init()
        
        automaticallyManagesSubnodes = true
    }
    
    open func updateSelected() {
        if let button = faveButtonNode.view as? FaveButton {
            DispatchQueue.main.async {
                button.setSelected(selected: self.currentlyFavorited, animated: false)
            }
        }
    }
    
    open override func didLoad() {
        super.didLoad()
        
        if let button = faveButtonNode.view as? FaveButton {
            button.setImage(FavoriteButtonNode.image, for: .normal)
            button.accessibilityLabel = accessibilityLabelString
            
            button.delegate = RelistenFaveButtonDelegate.sharedDelegate
            
            button.applyInit()
            
            button.setSelected(selected: currentlyFavorited, animated: false)
            
            button.addControlEvent(.touchUpInside) { (control: UIControl) in
                self.onFavorite()
            }
        }
    }
    
    open override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        faveButtonNode.style.layoutPosition = CGPoint(x: 0, y: 0)
        faveButtonNode.style.preferredSize = CGSize(width: 32, height: 32)
        
        return ASAbsoluteLayoutSpec(
            sizing: ASAbsoluteLayoutSpecSizing.sizeToFit,
            children: [ faveButtonNode ]
        )
    }
    
    @objc open func onFavorite() {
        currentlyFavorited = !currentlyFavorited
    }
}

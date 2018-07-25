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

public protocol FavoriteButtonDelegate {
    func didFavorite(currentlyFavorited : Bool)
    var favoriteButtonAccessibilityLabel : String { get }
}

open class FavoriteButtonNode : ASDisplayNode {
    private static let image = UIImage(named: "heart")
    
    private var _currentlyFavorited : Bool = false
    open var currentlyFavorited: Bool {
        get { return _currentlyFavorited }
        set {
            if _currentlyFavorited != newValue {
                _currentlyFavorited = newValue
                updateSelected()
            }
        }
    }
    
    open let faveButtonNode: ASDisplayNode
    
    open var disposal = Disposal()
    
    open var accessibilityLabelString = "Favorite"
    
    open var delegate : FavoriteButtonDelegate? = nil
    private var didInitButton : Bool = false
    
    public override init() {
        faveButtonNode = ASDisplayNode(viewBlock: { FaveButton(frame: CGRect(x: 0, y: 0, width: 32, height: 32)) })
        
        super.init()
        
        automaticallyManagesSubnodes = true
    }
    
    public convenience init(delegate: FavoriteButtonDelegate) {
        self.init()
        self.delegate = delegate
    }
    
    open func updateSelected() {
        if didInitButton {
            DispatchQueue.main.async {
                if let button = self.faveButtonNode.view as? FaveButton {
                    button.setSelected(selected: self.currentlyFavorited, animated: false)
                }
            }
        }
    }
    
    open override func didLoad() {
        super.didLoad()
        
        if let button = faveButtonNode.view as? FaveButton {
            button.setImage(FavoriteButtonNode.image, for: .normal)
            if let d = delegate {
                button.accessibilityLabel = d.favoriteButtonAccessibilityLabel
            } else {
                button.accessibilityLabel = accessibilityLabelString
            }
            
            button.delegate = RelistenFaveButtonDelegate.sharedDelegate
            
            button.applyInit()
            
            button.setSelected(selected: currentlyFavorited, animated: false)
            
            button.addControlEvent(.touchUpInside) { (control: UIControl) in
                self.onFavorite()
            }
            
            didInitButton = true
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
        _currentlyFavorited = !_currentlyFavorited
        if let delegate = delegate {
            delegate.didFavorite(currentlyFavorited : _currentlyFavorited)
        }
    }
}

extension FavoriteButtonDelegate {
    func didFavorite(currentlyFavorited : Bool) { }
    var favoriteButtonAccessibilityLabel : String { get { return "Favorite" } }
}

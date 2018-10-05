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

public protocol FavoriteButtonDelegate : class {
    func didFavorite(currentlyFavorited : Bool)
    var favoriteButtonAccessibilityLabel : String { get }
}

open class FavoriteButtonNode : ASDisplayNode, FaveButtonDelegate {
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
    
    public let faveButtonNode: ASDisplayNode
    
    open var disposal = Disposal()
    
    open var accessibilityLabelString = "Favorite"
    
    open weak var delegate : FavoriteButtonDelegate? = nil
    private var didInitButton : Bool = false
    
    open var normalColor : UIColor? {
        get {
            var color : UIColor? = nil
            performOnMainQueueSync {
                if let button = faveButtonNode.view as? FaveButton {
                    color = button.normalColor
                }
            }
            return color
        }
        set {
            performOnMainQueueSync {
                if let button = faveButtonNode.view as? FaveButton, let color = newValue {
                    button.normalColor = color
                }
            }
        }
    }
    
    public override init() {
        faveButtonNode = ASDisplayNode(viewBlock: { FaveButton(frame: CGRect(x: 0, y: 0, width: 32, height: 32), faveIconNormal: FavoriteButtonNode.image) })
        
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
            if let d = delegate {
                button.accessibilityLabel = d.favoriteButtonAccessibilityLabel
            } else {
                button.accessibilityLabel = accessibilityLabelString
            }
            
            button.delegate = self
            
            button.setSelected(selected: currentlyFavorited, animated: false)
            
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
    
    // MARK: FaveButtonDelegate
    public func instantCallback(_ faveButton: FaveButton, didSelected selected: Bool) {
        _currentlyFavorited = !_currentlyFavorited
        if let delegate = delegate {
            delegate.didFavorite(currentlyFavorited : _currentlyFavorited)
        }
    }
    
    private static func color(_ rgbColor: Int) -> UIColor{
        return UIColor(
            red:   CGFloat((rgbColor & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbColor & 0x00FF00) >> 8 ) / 255.0,
            blue:  CGFloat((rgbColor & 0x0000FF) >> 0 ) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    private let colors = [
        DotColors(first: color(0x7DC2F4), second: color(0xE2264D)),
        DotColors(first: color(0xF8CC61), second: color(0x9BDFBA)),
        DotColors(first: color(0xAF90F4), second: color(0x90D1F9)),
        DotColors(first: color(0xE9A966), second: color(0xF8C852)),
        DotColors(first: color(0xF68FA7), second: color(0xF6A2B8))
    ]
    
    public func faveButtonDotColors(_ faveButton: FaveButton) -> [DotColors]?{
        return colors
    }
    
    public func faveButton(_ faveButton: FaveButton, didSelected selected: Bool) {
    }
}

extension FavoriteButtonDelegate {
    func didFavorite(currentlyFavorited : Bool) { }
    var favoriteButtonAccessibilityLabel : String { get { return "Favorite" } }
}

//
//  PlaybackIndicatorNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 10/11/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import NAKPlaybackIndicatorView

public class PlaybackIndicatorNode : ASDisplayNode {
    public let indicatorNode: ASDisplayNode
    
    private var _stateShadow: NAKPlaybackIndicatorViewState = .paused
    public var state: NAKPlaybackIndicatorViewState {
        get {
            DispatchQueue.main.async { [weak self] in
                if let indicator = self?.indicatorNode.view as? NAKPlaybackIndicatorView, let s = self {
                    let st = indicator.state
                    s._stateShadow = st
                }
            }
            
            return _stateShadow
        }
        
        set {
            _stateShadow = newValue
            
            DispatchQueue.main.async { [weak self] in
                if let indicator = self?.indicatorNode.view as? NAKPlaybackIndicatorView, let s = self {
                    indicator.state = newValue
                    s.setNeedsLayout()
                }
            }
        }
    }

    public override init() {
        indicatorNode = ASDisplayNode(viewBlock: {
            NAKPlaybackIndicatorView(frame: CGRect(x: 0, y: 0, width: 12, height: 12), style: NAKPlaybackIndicatorViewStyle.default())
        })
        
        super.init()
        
        automaticallyManagesSubnodes = true
    }
    
    open override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        indicatorNode.style.layoutPosition = CGPoint(x: 0, y: 0)
        indicatorNode.style.preferredSize = CGSize(width: 12, height: 12)
        
        return ASAbsoluteLayoutSpec(
            sizing: ASAbsoluteLayoutSpecSizing.sizeToFit,
            children: [ indicatorNode ]
        )
    }
}

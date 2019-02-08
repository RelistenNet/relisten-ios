//
//  DebugSettingsNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 12/21/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Observable

public class DebugSettingsNode : ASCellNode {
    var disposal = Disposal()
    
    var isGeneratingTracks : Bool = false
    
    override public init() {
        recentlyPlayedTracksCountNode = ASTextNode("0 recently played tracks", textStyle: .body)
        
        generateRecentlyPlayedNode = ASButtonNode()
        generateRecentlyPlayedNode.setTitle("Generate 1000 recently played tracks »", with: UIFont.preferredFont(forTextStyle: .body), with: UIColor.flatRed(), for: .normal)
        generateRecentlyPlayedNode.setTitle("Generating tracks...", with: UIFont.preferredFont(forTextStyle: .body), with: AppColors.mutedText, for: .disabled)
        generateRecentlyPlayedNode.isEnabled = true
        
        recentlyPlayedTracksCount = MyLibrary.shared.recent.tracks.count
        
        super.init()
        
        generateRecentlyPlayedNode.addTarget(self, action: #selector(generateButtonPressed(_:)), forControlEvents: .touchUpInside)
        
        MyLibrary.shared.recent.tracks.observeWithValue { [weak self] (tracks, _) in
            guard let s = self else { return }
            
            s.recentlyPlayedTracksCount = tracks.count
        }.dispose(to: &disposal)
        
        automaticallyManagesSubnodes = true
        accessoryType = .none
    }
    
    var recentlyPlayedTracksCount : Int {
        didSet {
            self.updateDebugStatsNode()
        }
    }
    
    func updateDebugStatsNode() {
        DispatchQueue.main.async {
            self.recentlyPlayedTracksCountNode.attributedText = RelistenAttributedString("\(self.recentlyPlayedTracksCount) recently played tracks", textStyle: .body)
            if self.isGeneratingTracks == false {
                self.generateRecentlyPlayedNode.isEnabled = true
            } else {
                self.generateRecentlyPlayedNode.isEnabled = false
            }
            self.setNeedsLayout()
        }
    }
    
    @objc func generateButtonPressed(_ sender: UIButton) {
        generateRecentlyPlayedNode.isEnabled = false
        self.isGeneratingTracks = true
        TestDataGenerator.shared.generateRecentlyPlayed { (error) in
            self.isGeneratingTracks = false
            DispatchQueue.main.async {
                self.generateRecentlyPlayedNode.isEnabled = true
            }
        }
        
    }
    
    public let recentlyPlayedTracksCountNode : ASTextNode
    public let generateRecentlyPlayedNode : ASButtonNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let vert = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 16,
            justifyContent: .center,
            alignItems: .start,
            children: [
                recentlyPlayedTracksCountNode,
                generateRecentlyPlayedNode
            ]
        )
        vert.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16),
            child: vert
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}




//
//  SongNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 10/5/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit

public class SongNode : ASCellNode {
    public let song: SongWithShowCount

    public init(song: SongWithShowCount) {
        self.song = song
        
        self.songNameNode = ASTextNode(song.name, textStyle: .body)
        self.showCountNode = ASTextNode(song.shows_played_at.pluralize("show", "shows"), textStyle: .caption1)
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .disclosureIndicator
    }
    
    public let songNameNode: ASTextNode
    public let showCountNode: ASTextNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let songRow = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: ArrayNoNils(
                songNameNode,
                showCountNode
            )
        )
        songRow.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 8),
            child: songRow
        )
        l.style.alignSelf = .stretch
        
        return l
    }

}

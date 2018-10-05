//
//  AsyncDisplayKit.swift
//  Relisten
//
//  Created by Alec Gorge on 6/2/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit

public func RelistenAttributedString(_ string: String, font: UIFont, color: UIColor? = nil, alignment: NSTextAlignment? = nil, scale: CGFloat = 1.0, weight: FontWeight = .Regular) -> NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = alignment ?? NSTextAlignment.left
    
    var scaledFont = font
    if scale != 1.0 || weight != .Regular {
        scaledFont = font.font(scaledBy: scale, withDifferentWeight: weight)
    }
    
    return NSAttributedString(string: string, attributes: [
        NSAttributedString.Key.font: scaledFont,
        NSAttributedString.Key.foregroundColor: color ?? UIColor.darkText,
        NSAttributedString.Key.paragraphStyle: paragraphStyle
        ])
}

public func RelistenAttributedString(_ string: String, textStyle: UIFont.TextStyle, color: UIColor? = nil, alignment: NSTextAlignment? = nil, scale: CGFloat = 1.0, weight: FontWeight = .Regular) -> NSAttributedString {
    return RelistenAttributedString(string, font: UIFont.preferredFont(forTextStyle: textStyle), color: color, alignment: alignment, scale: scale, weight: weight)
}

extension ASTextNode {
    public convenience init(_ string: String, font: UIFont, color: UIColor? = nil, alignment: NSTextAlignment? = nil, scale: CGFloat = 1.0, weight: FontWeight = .Regular) {
        self.init()
        
        maximumNumberOfLines = 0
        attributedText = RelistenAttributedString(string, font: font, color: color, alignment: alignment, scale: scale, weight: weight)
    }
    
    public convenience init(_ string: String, textStyle: UIFont.TextStyle, color: UIColor? = nil, alignment: NSTextAlignment? = nil, scale: CGFloat = 1.0, weight: FontWeight = .Regular) {
        self.init()
        
        maximumNumberOfLines = 0
        attributedText = RelistenAttributedString(string, textStyle: textStyle, color: color, alignment: alignment, scale: scale, weight: weight)
    }
}

public func SpacerNode() -> ASLayoutSpec {
    let node = ASLayoutSpec()
    node.style.flexGrow = 1.0
    
    return node
}

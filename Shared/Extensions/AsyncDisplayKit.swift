//
//  AsyncDisplayKit.swift
//  Relisten
//
//  Created by Alec Gorge on 6/2/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit

public func RelistenAttributedStringAttributes(_ string: String, font: UIFont, color: UIColor? = nil, alignment: NSTextAlignment? = nil, scale: CGFloat = 1.0, weight: FontWeight = .Regular) -> [NSAttributedString.Key : Any] {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = alignment ?? NSTextAlignment.left
    
    var scaledFont = font
    if scale != 1.0 || weight != .Regular {
        scaledFont = font.font(scaledBy: scale, withDifferentWeight: weight)
    }
    
    return [
        NSAttributedString.Key.font: scaledFont,
        NSAttributedString.Key.foregroundColor: color ?? UIColor.darkText,
        NSAttributedString.Key.paragraphStyle: paragraphStyle
    ]
}

public func RelistenAttributedString(_ string: String, font: UIFont, color: UIColor? = nil, alignment: NSTextAlignment? = nil, scale: CGFloat = 1.0, weight: FontWeight = .Regular) -> NSAttributedString {
    return NSAttributedString(string: string, attributes: RelistenAttributedStringAttributes(string, font: font, color: color, alignment: alignment, scale: scale, weight: weight))
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

extension ASTextCellNode {
    public convenience init(_ string: String, font: UIFont, color: UIColor? = nil, alignment: NSTextAlignment? = nil, scale: CGFloat = 1.0, weight: FontWeight = .Regular, insets: UIEdgeInsets? = nil) {
        self.init(attributes: RelistenAttributedStringAttributes(string, font: font, color: color, alignment: alignment, scale: scale, weight: weight), insets: insets ?? UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 8))
        self.text = string
        self.textNode.maximumNumberOfLines = 0
    }
    
    public convenience init(_ string: String, textStyle: UIFont.TextStyle, color: UIColor? = nil, alignment: NSTextAlignment? = nil, scale: CGFloat = 1.0, weight: FontWeight = .Regular, insets: UIEdgeInsets? = nil) {
        self.init(attributes: RelistenAttributedStringAttributes(string, font: UIFont.preferredFont(forTextStyle: textStyle), color: color, alignment: alignment, scale: scale, weight: weight), insets: insets ?? UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 8))
        self.text = string
        self.textNode.maximumNumberOfLines = 0
    }
}

public func SpacerNode() -> ASLayoutSpec {
    let node = ASLayoutSpec()
    node.style.flexGrow = 1.0
    
    return node
}

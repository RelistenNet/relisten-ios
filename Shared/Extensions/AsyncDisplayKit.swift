//
//  AsyncDisplayKit.swift
//  Relisten
//
//  Created by Alec Gorge on 6/2/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit

public func RelistenAttributedString(_ string: String, font: UIFont, color: UIColor? = nil, alignment: NSTextAlignment? = nil) -> NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = alignment ?? NSTextAlignment.left
    
    return NSAttributedString(string: string, attributes: [
        NSAttributedStringKey.font: font,
        NSAttributedStringKey.foregroundColor: color ?? UIColor.darkText,
        NSAttributedStringKey.paragraphStyle: paragraphStyle
        ])
}

public func RelistenAttributedString(_ string: String, textStyle: UIFontTextStyle, color: UIColor? = nil, alignment: NSTextAlignment? = nil) -> NSAttributedString {
    return RelistenAttributedString(string, font: UIFont.preferredFont(forTextStyle: textStyle), color: color, alignment: alignment)
}

extension ASTextNode {
    public convenience init(_ string: String, font: UIFont, color: UIColor? = nil, alignment: NSTextAlignment? = nil) {
        self.init()
        
        maximumNumberOfLines = 0
        attributedText = RelistenAttributedString(string, font: font, color: color, alignment: alignment)
    }
    
    public convenience init(_ string: String, textStyle: UIFontTextStyle, color: UIColor? = nil, alignment: NSTextAlignment? = nil) {
        self.init()
        
        maximumNumberOfLines = 0
        attributedText = RelistenAttributedString(string, textStyle: textStyle, color: color, alignment: alignment)
    }
}

public func SpacerNode() -> ASLayoutSpec {
    let node = ASLayoutSpec()
    node.style.flexGrow = 1.0
    
    return node
}

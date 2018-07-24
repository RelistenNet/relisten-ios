//
//  RelistenFaveButtonDelegate.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/23/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import UIKit
import FaveButton

func color(_ rgbColor: Int) -> UIColor{
    return UIColor(
        red:   CGFloat((rgbColor & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbColor & 0x00FF00) >> 8 ) / 255.0,
        blue:  CGFloat((rgbColor & 0x0000FF) >> 0 ) / 255.0,
        alpha: CGFloat(1.0)
    )
}

public class RelistenFaveButtonDelegate : FaveButtonDelegate {
    static let sharedDelegate : RelistenFaveButtonDelegate = RelistenFaveButtonDelegate()
    
    let colors = [
        DotColors(first: color(0x7DC2F4), second: color(0xE2264D)),
        DotColors(first: color(0xF8CC61), second: color(0x9BDFBA)),
        DotColors(first: color(0xAF90F4), second: color(0x90D1F9)),
        DotColors(first: color(0xE9A966), second: color(0xF8C852)),
        DotColors(first: color(0xF68FA7), second: color(0xF6A2B8))
    ]
    
    public func faveButton(_ faveButton: FaveButton, didSelected selected: Bool) {
    }
    
    public func faveButtonDotColors(_ faveButton: FaveButton) -> [DotColors]?{
        return colors
    }
    
    public func instantCallback(_ faveButton: FaveButton, didSelected selected: Bool) {
        
    }
}

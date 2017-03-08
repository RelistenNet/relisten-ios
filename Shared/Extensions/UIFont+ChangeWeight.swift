//
//  UIFont+ChangeWeight.swift
//  Relisten
//
//  Created by Alec Gorge on 3/7/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

public enum FontWeight {
    case UltraLight,Thin,Light,Regular,Medium,Semibold,Bold,Heavy,Black
    
    var asFontWeightTraitValue: CGFloat {
        switch self {
        case .UltraLight: return UIFontWeightUltraLight
        case .Thin: return UIFontWeightThin
        case .Light: return UIFontWeightLight
        case .Regular: return UIFontWeightRegular
        case .Medium: return UIFontWeightMedium
        case .Semibold: return UIFontWeightSemibold
        case .Bold: return UIFontWeightBold
        case .Heavy: return UIFontWeightHeavy
        case .Black: return UIFontWeightBlack
        }
    }
}

public extension UIFont {
    public func font(scaledBy: CGFloat = 1.0, withDifferentWeight: FontWeight? = nil) -> UIFont {
        var attributes = fontDescriptor.fontAttributes

        if let newWeight = withDifferentWeight {
            attributes[UIFontWeightTrait] = newWeight.asFontWeightTraitValue
        }
        
        let descriptor = UIFontDescriptor(fontAttributes: attributes)
        let newFont = UIFont(descriptor:descriptor, size: descriptor.pointSize * scaledBy)
        
        return newFont
    }
}


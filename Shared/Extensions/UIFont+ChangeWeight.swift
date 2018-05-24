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
        case .UltraLight: return UIFont.Weight.ultraLight.rawValue
        case .Thin: return UIFont.Weight.thin.rawValue
        case .Light: return UIFont.Weight.light.rawValue
        case .Regular: return UIFont.Weight.regular.rawValue
        case .Medium: return UIFont.Weight.medium.rawValue
        case .Semibold: return UIFont.Weight.semibold.rawValue
        case .Bold: return UIFont.Weight.bold.rawValue
        case .Heavy: return UIFont.Weight.heavy.rawValue
        case .Black: return UIFont.Weight.black.rawValue
        }
    }
}

public extension UIFont {
    public func font(scaledBy: CGFloat = 1.0, withDifferentWeight: FontWeight? = nil) -> UIFont {
        if let newWeight = withDifferentWeight, newWeight == .Bold, let fd = fontDescriptor.withSymbolicTraits(.traitBold) {
            return UIFont(descriptor: fd, size: fontDescriptor.pointSize * scaledBy)
        }
        
        var attributes = fontDescriptor.fontAttributes

        if let newWeight = withDifferentWeight {
            let traits = attributes[.traits] as? [UIFontDescriptor.TraitKey: Any]
            
            if var t = traits {
                t[.weight] = newWeight.asFontWeightTraitValue
            }
            else {
                attributes[.traits] = [UIFontDescriptor.TraitKey.weight: newWeight.asFontWeightTraitValue]
            }
        }
        
        let descriptor = UIFontDescriptor(fontAttributes: attributes)
        let newFont = UIFont(descriptor:descriptor, size: descriptor.pointSize * scaledBy)
        
        return newFont
    }
}


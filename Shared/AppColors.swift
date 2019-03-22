//
//  AppColors.swift
//  Relisten
//
//  Created by Alec Gorge on 3/7/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit
import AGAudioPlayer
import ChameleonFramework
import Observable

public class _AppColors : Equatable {
    
    public let primary: UIColor
    public let textOnPrimary: UIColor
    public let highlight : UIColor
    
    public let soundboard: UIColor
    public let remaster: UIColor
    
    public let mutedText: UIColor
    public let lightGreyBackground: UIColor
    
    public let playerColors: AGAudioPlayerColors
    
    private let complements : [UIColor]
    
    public static func == (lhs: _AppColors, rhs: _AppColors) -> Bool {
        return lhs === rhs
    }
    
    public init(primary: UIColor, textOnPrimary: UIColor, highlight: UIColor? = nil, soundboard: UIColor, remaster: UIColor, mutedText: UIColor, lightGreyBackground: UIColor, playerColors: AGAudioPlayerColors) {
        self.primary = primary
        self.textOnPrimary = textOnPrimary
        self.soundboard = soundboard
        self.remaster = remaster
        self.mutedText = mutedText
        self.lightGreyBackground = lightGreyBackground
        self.playerColors = playerColors
        
        self.complements = NSArray(ofColorsWith: .complementary, using: self.primary, withFlatScheme: false) as! [UIColor]
        
        if let highlight = highlight {
            self.highlight = highlight
        } else {
            self.highlight = self.complements[0]
        }
    }
}

private let relistenPrimaryColor = UIColor(red:0, green:0.616, blue:0.753, alpha:1)
private let relistenPrimaryTextColor = UIColor.white
public let RelistenAppColors = _AppColors(
    primary: relistenPrimaryColor,
    textOnPrimary: relistenPrimaryTextColor,
    soundboard: UIColor(red:0.0/255.0, green:128.0/255.0, blue:95.0/255.0, alpha:1.0),
    remaster: UIColor(red:0, green:0.616, blue:0.753, alpha:1),
    mutedText: UIColor.gray,
    lightGreyBackground: UIColor(white: 0.97, alpha: 1.0),
    playerColors: AGAudioPlayerColors(main: relistenPrimaryColor, accent: relistenPrimaryTextColor)
)

private let phishODPrimaryColor = UIColor(red:0, green:128.0/255.0, blue:95.0/255.0, alpha:1)
private let phishODPrimaryTextColor = UIColor.white
public let PhishODAppColors = _AppColors(
    primary: phishODPrimaryColor,
    textOnPrimary: phishODPrimaryTextColor,
    soundboard: UIColor(red:0.0/255.0, green:128.0/255.0, blue:95.0/255.0, alpha:1.0),
    remaster: UIColor(red:0, green:0.616, blue:0.753, alpha:1),
    mutedText: UIColor.gray,
    lightGreyBackground: UIColor(white: 0.97, alpha: 1.0),
    playerColors: AGAudioPlayerColors(main: phishODPrimaryColor, accent: phishODPrimaryTextColor)
)

public var AppColors = RelistenAppColors
public let AppColorObserver = Observable<_AppColors>(AppColors)

public func AppColors_SwitchToPhishOD() {
    if AppColors != PhishODAppColors {
        AppColors = PhishODAppColors
        
        AppColorObserver.value = PhishODAppColors
    }
}

public func AppColors_SwitchToRelisten() {
    if AppColors != RelistenAppColors {
        AppColors = RelistenAppColors
        
        AppColorObserver.value = RelistenAppColors
    }
}

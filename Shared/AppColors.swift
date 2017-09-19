//
//  AppColors.swift
//  Relisten
//
//  Created by Alec Gorge on 3/7/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

public struct _AppColors {
    let primary: UIColor
    let textOnPrimary: UIColor
    
    let soundboard: UIColor
    let remaster: UIColor
    
    let mutedText: UIColor
    
    public init(primary: UIColor, textOnPrimary: UIColor, soundboard: UIColor, remaster: UIColor, mutedText: UIColor) {
        self.primary = primary
        self.textOnPrimary = textOnPrimary
        self.soundboard = soundboard
        self.mutedText = mutedText
        self.remaster = remaster
    }
}

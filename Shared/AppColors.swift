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
    
    public init(primary: UIColor, textOnPrimary: UIColor, soundboard: UIColor, remaster: UIColor) {
        self.primary = primary
        self.textOnPrimary = textOnPrimary
        self.soundboard = soundboard
        self.remaster = remaster
    }
}

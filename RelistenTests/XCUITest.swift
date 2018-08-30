//
//  XCUITest.swift
//  Relisten
//
//  Created by Jacob Farkas on 8/30/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import XCTest

// https://stackoverflow.com/questions/32646539/scroll-until-element-is-visible-ios-ui-automation-with-xcode7#33986610
extension XCUIElement {
    func scrollToElement(element: XCUIElement) {
        while !element.visible() {
            swipeUp()
        }
    }
    
    func visible() -> Bool {
        guard self.exists && !self.frame.isEmpty else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(self.frame)
    }
    
}

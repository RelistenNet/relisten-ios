//
//  PhishODUITests.swift
//  PhishODUITests
//
//  Created by Alec Gorge on 8/9/16.
//  Copyright © 2016 Alec Gorge. All rights reserved.
//

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

class PhishODUITests: XCTestCase {
    var app: XCUIApplication!
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        let tablesQuery = app.tables
        
        tablesQuery.buttons["everything"].tap()
        sleep(1)
        tablesQuery.buttons["years"].tap()
        sleep(1)
        tablesQuery.staticTexts["2017"].tap()
        sleep(1)
        let cell = tablesQuery.cells.containing(.staticText, identifier: "2017-07-25").element
        app.tables.element.scrollToElement(element: cell)
        cell.tap()
        sleep(1)
        tablesQuery.cells.containing(.staticText, identifier:"Lawn Boy").element(boundBy: 0).tap()
        sleep(5)
        
        snapshot("0_source")
        
        app.navigationBars["2017-07-25"].buttons["2017"].tap()
        // Swipe up so we see a little bit more interesting album art. Bakers dozen is all the same color.
        app.tables.element(boundBy: 1).swipeUp()
        sleep(1)
        snapshot("5_year")
        
        app.navigationBars["2017"].buttons["Years"].tap()
        
        sleep(1)
        snapshot("4_years")
        
        app.navigationBars["Years"].buttons["Phish"].tap()
        
        sleep(1)
        snapshot("3_artist")
        
        app.terminate()
        
        
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}

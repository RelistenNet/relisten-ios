//
//  RelistenUiTests.swift
//  RelistenUITests
//
//  Created by Alec Gorge on 8/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import XCTest
import SimulatorStatusMagic

class RelistenUiTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        SDStatusBarManager.sharedInstance().enableOverrides()
        
        continueAfterFailure = true
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        SDStatusBarManager.sharedInstance().disableOverrides()
    }
    
    func testExample() {
        let tablesQuery = app.tables
        
        tablesQuery.staticTexts["Grateful Dead"].firstMatch.tap()
        sleep(1)
        tablesQuery.buttons["everything"].tap()
        sleep(1)
        tablesQuery.buttons["years"].tap()
        sleep(1)
        
        var cell = tablesQuery.cells.containing(.staticText, identifier: "1977").element
        app.tables.element.scrollToElement(element: cell)
        cell.tap()
        sleep(1)
        
        cell = tablesQuery.cells.containing(.staticText, identifier: "1977-05-08").element
        app.tables.element.scrollToElement(element: cell)
        cell.tap()
        sleep(1)
        
        cell = tablesQuery.cells.containing(.staticText, identifier: "Source 1 of 16").element
        app.tables.element.scrollToElement(element: cell)
        cell.tap()
        sleep(1)
        
        cell = tablesQuery.cells.containing(.staticText, identifier: "Morning Dew").element
        app.tables.element.scrollToElement(element: cell)
        cell.tap()
        app.tables.element(boundBy: 1).swipeDown()
        sleep(5)
        
        snapshot("0_source")
        app.navigationBars["1977-05-08 #1"].buttons["1977-05-08 Sources"].tap()
        
        sleep(1)
        snapshot("1_sources")
        
        app.navigationBars["1977-05-08 Sources"].buttons["1977"].tap()
        
        sleep(1)
        snapshot("5_year")
        
        app.navigationBars["1977"].buttons["Years"].tap()
        
        sleep(1)
        snapshot("4_years")
        
        app.navigationBars["Years"].buttons["Grateful Dead"].tap()
        
        sleep(1)
        snapshot("3_artist")
        
        app.navigationBars["Grateful Dead"].buttons["Relisten"].tap()
        
        sleep(1)
        snapshot("2_artists")
        
        app.terminate()

        
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}

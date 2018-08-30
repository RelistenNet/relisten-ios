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
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["1970"]/*[[".cells.staticTexts[\"1970\"]",".staticTexts[\"1970\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(1)
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["1970-01-03"]/*[[".cells.staticTexts[\"1970-01-03\"]",".staticTexts[\"1970-01-03\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(1)
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Source 1 of 5"]/*[[".cells.staticTexts[\"Source 1 of 5\"]",".staticTexts[\"Source 1 of 5\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(1)
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Me and My Uncle"]/*[[".cells.staticTexts[\"Me and My Uncle\"]",".staticTexts[\"Me and My Uncle\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(5)
        
        snapshot("0_source")
        app.navigationBars["1970-01-03 #1"].buttons["1970-01-03 Sources"].tap()
        
        sleep(1)
        snapshot("1_sources")
        
        app.navigationBars["1970-01-03 Sources"].buttons["1970"].tap()
        
        sleep(1)
        snapshot("5_year")
        
        app.navigationBars["1970"].buttons["Years"].tap()
        
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

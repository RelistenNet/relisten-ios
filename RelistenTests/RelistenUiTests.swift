//
//  RelistenUiTests.swift
//  RelistenUITests
//
//  Created by Alec Gorge on 8/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import XCTest

class RelistenUiTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let tablesQuery = app.tables
        
        sleep(5)
        snapshot("main screen")
        tablesQuery.children(matching: .cell).element(boundBy: 3).staticTexts["Grateful Dead"].tap()
        
        sleep(5)
        snapshot("artist")
        tablesQuery.buttons["years"].tap()
        
        sleep(5)
        snapshot("years")
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["1973"]/*[[".cells.staticTexts[\"1973\"]",".staticTexts[\"1973\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        sleep(5)
        snapshot("sources")
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["1973-02-15"]/*[[".cells.staticTexts[\"1973-02-15\"]",".staticTexts[\"1973-02-15\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        sleep(5)
        snapshot("source")
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Source 2 of 7"]/*[[".cells.staticTexts[\"Source 2 of 7\"]",".staticTexts[\"Source 2 of 7\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}

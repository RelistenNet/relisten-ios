//
//  RelistenUITests.swift
//  RelistenUITests
//
//  Created by Jacob Farkas on 9/14/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import XCTest

class RelistenUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNoSmokeComesOut() {
        //var cell : XCUIElement
        let app = XCUIApplication()
        let tablesQuery = app.tables
        sleep(2)
        
        // SettingsViewController
        app.navigationBars.firstMatch.buttons["Settings"].tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        
        // Favorite/Unfavorite an artist
        let deadButton = tablesQuery.children(matching: .cell).containing(NSPredicate(format: "label CONTAINS 'Artist'")).containing(NSPredicate(format: "label CONTAINS 'Grateful Dead'"))
        deadButton.firstMatch.buttons["Favorite Artist"].tap()
        deadButton.firstMatch.buttons["Favorite Artist"].tap()
        
        // ArtistViewController
        tablesQuery.staticTexts["Grateful Dead"].firstMatch.tap()
        
        tablesQuery.buttons["everything"].tap()
        
        // YearsViewController
        tablesQuery.buttons["years"].tap()
        
        // YearViewController
        tablesQuery.cells.staticTexts["1966"].firstMatch.tap()
        
        // SourcesViewController
        tablesQuery.staticTexts["1966-01-08"].tap()
        
        // SourceViewController
        tablesQuery.staticTexts["Source 1 of 3"].tap()
        
        // Play a track
        tablesQuery.staticTexts["King Bee"].tap()

        // View full player, then close it
        app.buttons["Open Full Player"].tap()
        app.buttons["Shuffle"].firstMatch.tap()
        app.buttons["Loop"].tap()
        app.buttons["Previous"].tap()
        app.buttons["Next"].tap()
        app.buttons["Close Full Player"].tap()

        // Pause playback
        app.buttons["Pause"].tap()

        // Favorite/unfavorite
        let favoriteShowButton = tablesQuery/*@START_MENU_TOKEN@*/.buttons["Favorite Show"]/*[[".cells.buttons[\"Favorite Show\"]",".buttons[\"Favorite Show\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        favoriteShowButton.tap()
        favoriteShowButton.tap()

        // Share
        app.buttons["Share"].tap()
        // https://stackoverflow.com/questions/58381626/how-to-dismiss-the-uiactivityviewcontroller-during-a-ui-test-with-xcode-11-ios
        app.otherElements.element(boundBy: 1).buttons.element(boundBy: 0).tap()

        // Mini player dots
        app.buttons["Mini Dots"].tap()
        app.buttons["Cancel"].tap()

        // Credits (SFSafariViewController)
        let table = tablesQuery.element(boundBy: 1)
        table.swipeUp()
        table.swipeUp()
        table.swipeUp()
        table.staticTexts["View on archive.org"].tap()
        app.buttons["Done"].tap()
        table.swipeDown()
        table.swipeDown()
        table.swipeDown()
        
        // SourceDetailsViewController
        tablesQuery.staticTexts["See details, taper notes, reviews & more ›"].tap()
        
        // LongTextViewController
        tablesQuery.staticTexts["Taper Notes"].tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        
        // ReviewsViewController
        tablesQuery.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Review'")).firstMatch.tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        
        // VenueViewController
        tablesQuery.staticTexts["Fillmore Auditorium"].tap()
        
        // Back to ArtistViewController
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        
        // SongsViewController
        tablesQuery.buttons["songs"].tap()
        
        // SongsViewController
        tablesQuery.staticTexts["Alabama Getaway"].tap()
        
        // Back to ArtistViewController
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        
        // VenuesViewController
        tablesQuery.buttons["venues"].tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        
        
        tablesQuery.buttons["discover"].tap() 
        // TopShowsViewController
        tablesQuery.buttons["top"].tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        
        // Random Show
        tablesQuery.buttons["random"].tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        
        
        tablesQuery.buttons["recent"].tap()
        // RecentlyPerformedViewController
        tablesQuery.buttons["performed"].tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        
        // RecentlyAddedViewController
        tablesQuery.buttons["updated"].tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        
        
        tablesQuery.buttons["my shows"].tap()
        // MyLibraryViewController
        tablesQuery.buttons["my favorites"].tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        
        // MyRecentlyPlayedViewController
        tablesQuery.buttons["my recents"].tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        
        // DownloadedViewController
        tablesQuery.buttons["downloaded"].tap()
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
    }
}

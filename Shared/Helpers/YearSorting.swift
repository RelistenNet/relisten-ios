//
//  YearSorting.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/18/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

public func sortedYears(from years : [Year], for artist : SlimArtist? = nil) -> [Year]{
    var shouldSortDescending = false
    
    // Sort anyway because we have to find the most recent year in the array
    let sortedYears : [Year] = years.sorted(by: { (yearA, yearB) in
        if let yearAInt = Int(yearA.year), let yearBInt = Int(yearB.year) {
            return yearAInt > yearBInt
        }
        return true
    })
    
    if let artist = artist, artist.shouldSortYearsDescending {
        shouldSortDescending = true
    }
    
    // Sort descending if the band has performed within the last two years
    if let firstYear = sortedYears.first, let mostRecentYear = Int(firstYear.year) {
        let calendar = Calendar(identifier: .gregorian)
        let currentYear = calendar.component(.year, from: Date())
        shouldSortDescending = (currentYear - mostRecentYear) < 2;
        
    }

    if shouldSortDescending {
        return sortedYears
    } else {
        return years
    }
}

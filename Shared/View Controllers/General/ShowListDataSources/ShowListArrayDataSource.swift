//
//  ShowListArrayDataSource.swift
//  RelistenShared
//
//  Created by Alec Gorge on 3/20/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import Foundation
import SINQ

public protocol ShowListArrayDataSourceShowExtractor: class {
    associatedtype ExtractionTarget
    associatedtype FullMatchingData
    
    func extractShowAndSource(forData: ShowCellDataSource, withMatchingData: FullMatchingData) -> ShowWithSingleSource?
    func extractCellShows(forData: ExtractionTarget) -> [(FullMatchingData, ShowCellDataSource)]
}

public class ShowListArrayDataSourceDefaultExtractor<T> : ShowListArrayDataSourceShowExtractor where T: Show {
    public typealias ExtractionTarget = [T]
    public typealias FullMatchingData = T
    
    public let providedArtist: ArtistWithCounts?
    
    public init(providedArtist: ArtistWithCounts? = nil) {
        self.providedArtist = providedArtist
    }
    
    public func extractShowAndSource(forData: ShowCellDataSource, withMatchingData: T) -> ShowWithSingleSource? {
        let artist = providedArtist ?? forData.artistDataSource
        
        return ShowWithSingleSource(show: withMatchingData, source: nil, artist: artist)
    }
    
    public func extractCellShows(forData: [T]) -> [(T, ShowCellDataSource)] {
        return Array(zip(forData, forData as [ShowCellDataSource]))
    }
}

public enum ShowSorting {
    case noSorting
    case ascending
    case descending
}

private typealias Group<K, V> = (key: K, values: [V])

public class ShowListArrayDataSource<T, M, E: ShowListArrayDataSourceShowExtractor> : ShowListDataSource where E.ExtractionTarget == T, E.FullMatchingData == M {
    public typealias DataType = T
    
    private var data: T? = nil
    private weak var extractor: E? = nil
    
    // TODO: Sort the shows when this value changes and refresh the view
    private var sort : ShowSorting
    private let tourSections: Bool
    private let artistSections: Bool

    public init(extractor: E, sort: ShowSorting = .ascending, tourSections: Bool = true, artistSections: Bool = false) {
        self.extractor = extractor
        self.sort = sort
        self.tourSections = tourSections
        self.artistSections = artistSections
    }
    
    private var allShows: [(M, ShowCellDataSource)] = []
    private var groupedShows: [Group<String, (M, ShowCellDataSource)>] = []
    private var filteredShows: [Group<String, (M, ShowCellDataSource)>] = []
    private var indexTitles: [String]? = nil
    
    // MARK: ShowListDataSource
    
    public func showListDataChanged(_ data: T) {
        self.data = data
        
        if let e = extractor {
            let extractedShows = e.extractCellShows(forData: data)
            let grouped = sortAndGroupShows(extractedShows)
            self.allShows = extractedShows
            self.groupedShows = grouped
            
            if artistSections {
                indexTitles = groupedShows.map({ String($0.key.prefix(1)) })
            }
        }
    }
    
    private var lastSearchText: String? = nil
    private var lastScope: String = "All"
    
    public func showListFilterTextChanged(_ text: String, inScope scope: String) {
        if lastSearchText != text || lastScope != scope {
            self.filteredShows = sortAndGroupShows(self.allShows, searchText: text, scope: scope)
            
            lastSearchText = text
            lastScope = scope
        }
    }
    
    public func title(forSection section: Int, whileFiltering isFiltering: Bool) -> String? {
        guard tourSections || artistSections else { return nil }
        return items(whileFiltering: isFiltering)[section].key
    }
    
    public func numberOfSections(whileFiltering isFiltering: Bool) -> Int {
        return items(whileFiltering: isFiltering).count
    }
    
    public func numberOfShows(in section: Int, whileFiltering isFiltering: Bool) -> Int {
        return items(whileFiltering: isFiltering)[section].values.count
    }
    
    public func showWithSingleSource(at indexPath: IndexPath, whileFiltering isFiltering: Bool) -> ShowWithSingleSource? {
        let ds = items(whileFiltering: isFiltering)[indexPath.section].values[indexPath.row]
        
        if let e = extractor {
            return e.extractShowAndSource(forData: ds.1, withMatchingData: ds.0)
        }
        
        return nil
    }
    
    public func cellShow(at indexPath: IndexPath, whileFiltering isFiltering: Bool) -> ShowCellDataSource? {
        return items(whileFiltering: isFiltering)[indexPath.section].values[indexPath.row].1
    }
    
    public func sectionIndexTitles(whileFiltering isFiltering: Bool) -> [String]? {
        guard artistSections else { return nil }
        
        return indexTitles
    }
    
    // MARK: Data Organization
    
    fileprivate func sortAndGroupShows(_ data: [(M, ShowCellDataSource)], searchText: String? = nil, scope: String = "All") -> [Group<String, (M, ShowCellDataSource)>] {
        var sinqData = sinq(data)
            .filter({ (show) -> Bool in
                return ((scope == "All" || self.scopeMatchesShow(show.1, scope: scope)) &&
                    (searchText == nil || searchText == "" || self.searchStringMatchesShow(show.1, searchText: searchText!)))
            })
        
        switch sort {
        case .ascending:
            sinqData = sinqData.orderBy({
                return $0.1.date.timeIntervalSinceReferenceDate
            })
        case .descending:
            sinqData = sinqData.orderByDescending({
                return $0.1.date.timeIntervalSinceReferenceDate
            })
        default:
            break
        }
        
        var groupedData : [Group<String, (M, ShowCellDataSource)>]
        
        if tourSections {
            groupedData = []
            var currentGroupKey: String? = nil;
            var currentGroupValues: [(M, ShowCellDataSource)]? = nil
            
            sinqData.orderBy({ $0.1.date }).each { d in
                let show = d.1
                let tourName = show.tourDataSource?.name ?? ""
                
                if currentGroupKey != tourName {
                    if let currKey = currentGroupKey, let currValue = currentGroupValues {
                        groupedData.append(Group(key: currKey, values: currValue))
                        
                        currentGroupKey = nil
                        currentGroupValues = nil
                    }
                    
                    currentGroupKey = tourName
                    currentGroupValues = [d]
                }
                else {
                    currentGroupValues?.append(d)
                }
            }
            
            if let currKey = currentGroupKey, let currValue = currentGroupValues {
                groupedData.append(Group(key: currKey, values: currValue))
            }
        }
        else if artistSections {
            groupedData = sinqData
                .groupBy({ $0.1.artistDataSource?.name ?? "" })
                .orderBy({ $0.key })
                .toArray()
                .map({ (g) -> Group<String, (M, ShowCellDataSource)> in
                    Group<String, (M, ShowCellDataSource)>(key: g.key, values: g.values.toArray())
                })
        }
        else {
            groupedData = [Group(key: "", values: sinqData.toArray())]
        }
        
        return groupedData
    }
    
    // MARK: Filtering
    
    func searchStringMatchesShow(_ show: ShowCellDataSource, searchText: String) -> Bool {
        if let venue = show.venueDataSource {
            if venue.name.lowercased().contains(searchText) { return true }
            if let pastName = venue.past_names, pastName.lowercased().contains(searchText) { return true }
            if venue.location.lowercased().contains(searchText) { return true }
        }
        
        if let tour = show.tourDataSource {
            if tour.name.lowercased().contains(searchText) { return true }
        }
        
        if let source = show.sourceDataSource {
            if let taper = source.taper, taper.lowercased().contains(searchText) { return true }
            if let transferrer = source.transferrer, transferrer.lowercased().contains(searchText) { return true }
        }
        
        if searchText == "sbd" || searchText == "soundboard" {
            if show.has_soundboard_source { return true }
        }
        
        return false
    }
    
    func scopeMatchesShow(_ show: ShowCellDataSource, scope: String) -> Bool {
        if scope == "SBD" {
            if show.has_soundboard_source { return true }
            if let source = show.sourceDataSource {
                if source.is_soundboard { return true }
            }
        }
        
        return false
    }
    
    private func items(whileFiltering isFiltering: Bool) -> [Group<String, (M, ShowCellDataSource)>] {
        if isFiltering {
            return filteredShows
        } else {
            return groupedShows
        }
    }
    
    private func showWithSource(at indexPath: IndexPath, whileFiltering isFiltering: Bool) -> (M, ShowCellDataSource)? {
        var retval : (M, ShowCellDataSource)? = nil
        
        let items = self.items(whileFiltering: isFiltering)
        if indexPath.section >= 0, indexPath.section < items.count {
            let allItems = items[indexPath.section].values
            if indexPath.row >= 0, indexPath.row < allItems.count {
                retval = allItems[indexPath.row]
            }
        }
        return retval
    }
}

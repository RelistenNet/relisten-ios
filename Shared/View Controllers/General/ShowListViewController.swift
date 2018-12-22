//
//  ShowListViewController.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/16/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import Siesta
import SINQ
import AsyncDisplayKit

public struct ShowWithSingleSource {
    public let show : Show
    public let source : SourceFull?
}

// (farkas) This is real similar to GroupedViewController. I'd love to unify these two classes at some point. 
public class ShowListViewController<T> : RelistenTableViewController<T>, UISearchResultsUpdating, UISearchBarDelegate {
    internal let artist: Artist
    
    var allShows: [ShowWithSingleSource] = []
    private var groupedShows: [Grouping<String, ShowWithSingleSource>] = []
    private var filteredShows: [Grouping<String, ShowWithSingleSource>] = []
    internal let showMappingQueue = DispatchQueue(label: "live.relisten.ShowListViewController.mappingQueue")
    
    let searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    // TODO: Sort the shows when this value changes and refresh the view
    var shouldSortShows : Bool = true
    internal let tourSections: Bool
    
    public required init(artist: Artist, tourSections: Bool, enableSearch: Bool = true) {
        self.artist = artist
        self.tourSections = artist.features.tours && tourSections
        
        super.init(useCache: true, refreshOnAppear: true)
        
        self.tableNode.view.sectionIndexColor = AppColors.primary
        self.tableNode.view.sectionIndexMinimumDisplayRowCount = 4
        
        if enableSearch {
            // Setup the Search Controller
            searchController.searchResultsUpdater = self
            searchController.obscuresBackgroundDuringPresentation = false
            
            searchController.searchBar.delegate = self
            if let buttonTitles = self.scopeButtonTitles {
                searchController.searchBar.scopeButtonTitles = buttonTitles
                searchController.searchBar.showsScopeBar = true
                let regularFont = UIFont.preferredFont(forTextStyle: .body)
                searchController.searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: AppColors.textOnPrimary,
                                                                                 NSAttributedString.Key.font: regularFont], for: .normal)
                let boldFont = regularFont.font(scaledBy: 1.0, withDifferentWeight: .Bold)
                searchController.searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: AppColors.textOnPrimary,
                                                                                 NSAttributedString.Key.font: boldFont], for: .selected)
            }
            
            searchController.searchBar.placeholder = self.searchPlaceholder
            searchController.searchBar.barStyle = .blackTranslucent
            searchController.searchBar.backgroundColor = AppColors.primary
            searchController.searchBar.barTintColor = AppColors.textOnPrimary
            searchController.searchBar.tintColor = AppColors.textOnPrimary
            
            navigationItem.searchController = searchController
            definesPresentationContext = true
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    // MARK: Subclass Overrides
    public override var resource: Resource? { get { return nil } }
    
    public func extractShowsAndSource(forData: T) -> [ShowWithSingleSource] {
        fatalError("need to override this")
    }
    
    public func layout(show: Show, atIndex: IndexPath) -> ASCellNodeBlock {
        return { ShowCellNode(show: show) }
    }
    
    func searchStringMatchesShow(_ show: ShowWithSingleSource, searchText: String) -> Bool {
        if let venue = show.show.venue {
            if venue.name.lowercased().contains(searchText) { return true }
            if let pastName = venue.past_names, pastName.lowercased().contains(searchText) { return true }
            if venue.location.lowercased().contains(searchText) { return true }
        }
        
        if let tour = show.show.tour {
            if tour.name.lowercased().contains(searchText) { return true }
        }
        
        if let source = show.source {
            if let taper = source.taper, taper.lowercased().contains(searchText) { return true }
            if let transferrer = source.transferrer, transferrer.lowercased().contains(searchText) { return true }
            if source.containsTrack(where: { $0.title.lowercased().contains(searchText) }) { return true }
        }
        
        if searchText == "sbd" || searchText == "soundboard" {
            if show.show.has_soundboard_source { return true }
        }
        
        return false
    }
    
    func scopeMatchesShow(_ show: ShowWithSingleSource, scope: String) -> Bool {
        if scope == "SBD" {
            if show.show.has_soundboard_source { return true }
            if let source = show.source {
                if source.is_soundboard { return true }
            }
        }
        
        return false
    }
    
    var scopeButtonTitles : [String]? { get { return ["All", "SBD"] } }
    var searchPlaceholder : String { get { return "Search" } }
    
    // MARK: Updating Data
    
    // Use loadData if you're not loading via the network (for downloaded/favorited/etc views)
    // (farkas) This is admittedly hacky, and I need to add better locking around reloading of data in RelistenTableViewController in general
    public func loadData(_ data: T) {
        let extractedShows = self.extractShowsAndSource(forData: data)
        let grouped = sortAndGroupShows(extractedShows)
        showMappingQueue.async {
            self.latestData = data
            self.allShows = extractedShows
            self.groupedShows = grouped
            DispatchQueue.main.async {
                self.tableNode.reloadData()
            }
        }
    }
    
    public override func dataChanged(_ data: T) {
        let extractedShows = self.extractShowsAndSource(forData: data)
        let grouped = sortAndGroupShows(extractedShows)
        showMappingQueue.async {
            self.allShows = extractedShows
            self.groupedShows = grouped
            DispatchQueue.main.async {
                self.tableNode.reloadData()
            }
        }
    }
    
    func sortAndGroupShows(_ data: [ShowWithSingleSource], searchText: String? = nil, scope: String = "All") -> [Grouping<String, ShowWithSingleSource>] {
        var sinqData = sinq(data)
            .filter({ (show) -> Bool in
                return ((scope == "All" || self.scopeMatchesShow(show, scope: scope)) &&
                        (searchText == nil || searchText == "" || self.searchStringMatchesShow(show, searchText: searchText!)))
            })
        
        if artist.shouldSortYearsDescending, shouldSortShows {
            sinqData = sinqData.orderByDescending({
                return $0.show.date.timeIntervalSinceReferenceDate
            })
        }
        
        var groupedData : SinqSequence<Grouping<String, ShowWithSingleSource>>!
        if tourSections {
            groupedData = sinqData.groupBy({
                return $0.show.tour?.name ?? ""
            })
        } else {
            groupedData = sinqData.groupBy({_ in return "" })
        }
        
        return groupedData.toArray()
            .sorted(by: { (a, b) -> Bool in
                return a.key <= b.key
            })
    }
    
    func filteredItemsForSearchText(_ searchText: String, scope: String = "All") -> [Grouping<String, ShowWithSingleSource>] {
        return sortAndGroupShows(allShows, searchText: searchText, scope: scope)
    }
    
    private var curItems : [Grouping<String, ShowWithSingleSource>] {
        get {
            dispatchPrecondition(condition: .onQueue(self.showMappingQueue))
            
            if isFiltering() {
                return filteredShows
            } else {
                return groupedShows
            }
        }
    }
    
    private func showWithSource(at indexPath : IndexPath) -> ShowWithSingleSource? {
        dispatchPrecondition(condition: .onQueue(self.showMappingQueue))
        
        var retval : ShowWithSingleSource? = nil
        
        let items = curItems
        if indexPath.section >= 0, indexPath.section < items.count {
            let allItems = items[indexPath.section].values
            if indexPath.row >= 0, indexPath.row < allItems.count() {
                retval = allItems.elementAt(indexPath.row)
            }
        }
        return retval
    }
    
    // MARK: Table Data Source
    override public func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        var show: ShowWithSingleSource? = nil
        showMappingQueue.sync {
            show = showWithSource(at: indexPath)
        }
        if let show = show {
            let sourcesViewController = SourcesViewController(artist: artist, show: show.show)
            sourcesViewController.presentIfNecessary(navigationController: navigationController, forSource: show.source)
        }
    }
    
    override public func numberOfSections(in tableNode: ASTableNode) -> Int {
        var count : Int = 0
        showMappingQueue.sync {
            count = curItems.count
        }
        return count
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        var count : Int = 0
        showMappingQueue.sync {
            let items = curItems
            guard section >= 0, section < items.count else {
                return
            }
            count = items[section].values.count()
        }
        return count
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tourSections == false {
            return nil
        }
        
        var title : String? = nil
        showMappingQueue.sync {
            let items = curItems
            guard section >= 0, section < items.count else {
                return
            }
            title = items[section].values.first().show.tour?.name
        }
        return title
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        var retval : ASCellNodeBlock? = nil
        
        showMappingQueue.sync {
            if let showWithSource = showWithSource(at: indexPath) {
                retval = layout(show: showWithSource.show, atIndex: indexPath)
            }
        }
        
        if let retval = retval {
            return retval
        } else {
            return { ASCellNode() }
        }
    }
    
    //MARK: Searching
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return (searchController.isActive && !searchBarIsEmpty()) || searchBarScopeIsFiltering
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        let searchTextLC = searchText.lowercased()
        showMappingQueue.async {
            self.filteredShows = self.filteredItemsForSearchText(searchTextLC, scope: scope)
            DispatchQueue.main.async {
                self.tableNode.reloadData()
            }
        }
    }
    
    //MARK: UISearchResultsUpdating
    public func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles?[searchBar.selectedScopeButtonIndex] ?? "All"
        if let searchText = searchController.searchBar.text {
            filterContentForSearchText(searchText, scope: scope)
        }
    }
    
    //MARK: UISearchBarDelegate
    public func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

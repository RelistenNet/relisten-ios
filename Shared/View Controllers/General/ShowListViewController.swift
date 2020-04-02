//
//  ShowListViewController.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/16/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import Siesta
import AsyncDisplayKit
import RealmSwift
import DZNEmptyDataSet

public struct ShowWithSingleSource {
    public let show : Show
    public let source : SourceFull?
    public let artist : Artist?
}

public struct ShowSourceArtistUUIDs {
    public let showUUID: UUID
    public let sourceUUID: UUID?
    public let artistUUID: UUID
}

extension HasSourceAndShow {
    func toUUIDs() -> ShowSourceArtistUUIDs {
        return ShowSourceArtistUUIDs(
            showUUID: UUID(uuidString: show_uuid)!,
            sourceUUID: UUID(uuidString: source_uuid)!,
            artistUUID: UUID(uuidString: artist_uuid)!
        )
    }
}

public protocol ShowListDataSource: class {
    associatedtype DataType
    
    func showListDataChanged(_ data: DataType)
    func showListFilterTextChanged(_ text: String, inScope scope: String)
    
    func title(forSection section: Int, whileFiltering isFiltering: Bool) -> String?
    func sectionIndexTitles(whileFiltering isFiltering: Bool) -> [String]?
    func numberOfSections(whileFiltering isFiltering: Bool) -> Int
    func numberOfShows(in section: Int, whileFiltering isFiltering: Bool) -> Int
    
    func cellShow(at indexPath: IndexPath, whileFiltering isFiltering: Bool) -> ShowCellDataSource?
    func showWithSingleSource(at indexPath: IndexPath, whileFiltering isFiltering: Bool) -> ShowWithSingleSource?
}

public class NewShowListRealmViewController<T: RealmCollectionValue> : NewShowListViewController<[ShowSourceArtistUUIDs], ShowListLazyDataSource> where T : HasSourceAndShow {
    private let strongDataSource: ShowListLazyDataSource
    
    public required init(query: Results<T>, providedArtist artist: ArtistWithCounts? = nil, enableSearch: Bool = true, tourSections: Bool? = nil, artistSections: Bool? = nil) {
        strongDataSource = ShowListLazyDataSource(providedArtist: artist, tourSections: tourSections, artistSections: artistSections)
        super.init(withDataSource: strongDataSource, enableSearch: enableSearch)
        
        query.observe { [weak self] _ in
            let uuids = Array(query).map({ $0.toUUIDs() })
            
            // dataChanged reloads the tableview
            self?.dataChanged(uuids)
        }.dispose(to: &disposal)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style) {
        fatalError("init(useCache:refreshOnAppear:style:) has not been implemented")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(withDataSource dataSource: ShowListLazyDataSource, enableSearch: Bool) {
        fatalError("init(withDataSource:enableSearch:) has not been implemented")
    }
}

public class NewShowListArrayViewController<T> : NewShowListViewController<[T], ShowListArrayDataSource<[T], T, ShowListArrayDataSourceDefaultExtractor<T>>> where T: Show {
    private let strongDataSource: ShowListArrayDataSource<[T], T, ShowListArrayDataSourceDefaultExtractor<T>>
    private let strongExtractor: ShowListArrayDataSourceDefaultExtractor<T>
    
    public required init(providedArtist artist: ArtistWithCounts? = nil, sort: ShowSorting = .descending, tourSections: Bool = true, artistSections: Bool = false, enableSearch: Bool = true) {
        strongExtractor = ShowListArrayDataSourceDefaultExtractor(providedArtist: artist)
        strongDataSource = ShowListArrayDataSource(extractor: strongExtractor, sort: sort)
        super.init(withDataSource: strongDataSource, enableSearch: enableSearch)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style) {
        fatalError("init(useCache:refreshOnAppear:style:) has not been implemented")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(withDataSource dataSource: ShowListArrayDataSource<[T], T, ShowListArrayDataSourceDefaultExtractor<T>>, enableSearch: Bool) {
        fatalError("init(withDataSource:enableSearch:) has not been implemented")
    }
}

public class NewShowListViewController<T, DataSource: ShowListDataSource> : RelistenTableViewController<T>, UISearchResultsUpdating, UISearchBarDelegate, DZNEmptyDataSetSource where DataSource.DataType == T {
    internal let showMappingQueue = DispatchQueue(label: "live.relisten.ShowListViewController.mappingQueue")
    
    let searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    internal let enableSearch: Bool
    
    internal weak var dataSource: DataSource? = nil
    
    public required init(withDataSource dataSource: DataSource, enableSearch: Bool = true) {
        self.enableSearch = enableSearch
        self.dataSource = dataSource
        
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
            }
            // Hide the scope bar for now- we'll reveal it when the user taps on the search field
            searchController.searchBar.showsScopeBar = true
            
            searchController.searchBar.placeholder = self.searchPlaceholder
//            searchController.searchBar.searchBarStyle = .prominent
            searchController.searchBar.barStyle = .black
            searchController.searchBar.isTranslucent = true
            searchController.searchBar.backgroundColor = AppColors.primary
            searchController.searchBar.barTintColor = AppColors.textOnPrimary
            searchController.searchBar.tintColor = AppColors.textOnPrimary

            applySearchBarStyle()
            
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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableNode.view.emptyDataSetSource = self
        tableNode.view.tableFooterView = UIView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        if enableSearch {
            navigationItem.hidesSearchBarWhenScrolling = false
            applySearchBarStyle()
        }
        super.viewWillAppear(animated)
    }
    
    func applySearchBarStyle() {
        let placeholder = NSAttributedString(string: "Search",
                                             attributes: [
                                                .foregroundColor: AppColors.textOnPrimary.withAlphaComponent(0.80)
        ])
        let searchTextField = searchController.searchBar.searchTextField
        searchTextField.attributedPlaceholder = placeholder

        DispatchQueue.global().async {
            DispatchQueue.main.async {
                searchTextField.leftView?.tintColor = AppColors.textOnPrimary
                searchTextField.attributedPlaceholder = placeholder
            }
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        if enableSearch {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
        super.viewWillAppear(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        if enableSearch {
            searchController.isActive = false
        }
        super.viewWillDisappear(animated)
    }
    
    // MARK: Subclass Overrides
    public override var resource: Resource? { get { return nil } }
    
    public func layout(show: ShowWithSingleSource, atIndex: IndexPath) -> ASCellNodeBlock {
        return { ShowCellNode(show: show.show) }
    }
    
    var scopeButtonTitles : [String]? { get { return ["All", "SBD"] } }
    var searchPlaceholder : String { get { return "Filter" } }
    
    // MARK: Updating Data
    
    public override func dataChanged(_ data: T) {
        guard let ds = dataSource else { return }

        showMappingQueue.async {
            ds.showListDataChanged(data)
            
            DispatchQueue.main.async {
                self.render()
            }
        }
    }
    
    // MARK: Table Data Source
    override public func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        guard let ds = dataSource else { return }
        
        var show: ShowWithSingleSource? = nil
        let filtering = isFiltering()
        showMappingQueue.sync {
            show = ds.showWithSingleSource(at: indexPath, whileFiltering: filtering)
        }
        
        if let s = show, let a = s.artist {
            let sourcesViewController = SourcesViewController(artist: a, show: s.show)
            sourcesViewController.presentIfNecessary(navigationController: navigationController, forSource: s.source)
        }
    }
    
    override public func numberOfSections(in tableNode: ASTableNode) -> Int {
        guard let ds = dataSource else { return 0 }
        
        var count : Int = 0
        let filtering = isFiltering()
        showMappingQueue.sync {
            count = ds.numberOfSections(whileFiltering: filtering)
        }
        return count
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        guard let ds = dataSource else { return 0 }

        var count : Int = 0
        let filtering = isFiltering()
        showMappingQueue.sync {
            count = ds.numberOfShows(in: section, whileFiltering: filtering)
        }
        return count
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let ds = dataSource else { return nil }

        var title : String? = nil
        let filtering = isFiltering()
        showMappingQueue.sync {
            title = ds.title(forSection: section, whileFiltering: filtering)
        }
        return title
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        guard let ds = dataSource else { return { ASCellNode() } }

        var retval : ASCellNodeBlock? = nil
        
        let filtering = isFiltering()
        showMappingQueue.sync {
            if let showWithSource = ds.showWithSingleSource(at: indexPath, whileFiltering: filtering) {
                retval = self.layout(show: showWithSource, atIndex: indexPath)
            }
        }
        
        if let retval = retval {
            return retval
        } else {
            return { ASCellNode() }
        }
    }
    
    public override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard let ds = dataSource else { return nil }

        let letters = ds.sectionIndexTitles(whileFiltering: isFiltering())
        return letters
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
        guard let ds = dataSource else { return }
        
        let searchTextLC = searchText.lowercased()
        
        showMappingQueue.async {
            ds.showListFilterTextChanged(searchTextLC, inScope: scope)
            
            DispatchQueue.main.async {
                self.render()
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
    
    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.sizeToFit()
        return true
    }
    
    public func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.sizeToFit()
        return true
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.sizeToFit()
    }
    
    //MARK: UISearchBarDelegate
    public func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
    
    // This is kind of dumb, but due to some bugs in LayerKit we need to hide the scope bar until the search field is tapped,
    //  otherwise the scope bars show up while pushing/popping this view controller.
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.showsScopeBar = true
    }
    
    // MARK: DZNEmptyDataSetDelegate

    // MARK: DZNEmptyDataSetSource
    public func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -50.0
    }
    
    public func spaceHeight(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 22.0
    }
    
    public func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "music")?.tinted(color: .lightGray)
    }
    
    public func titleTextForEmptyDataSet(_ scrollView: UIScrollView) -> String {
        return "No Shows"
    }
    
    public func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString {
        let text = titleTextForEmptyDataSet(scrollView)
        
        let attributes = [
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline),
            NSAttributedString.Key.foregroundColor: UIColor.darkGray,
        ]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    public func descriptionTextForEmptyDataSet(_ scrollView: UIScrollView) -> String {
        return ""
    }
    
    public func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString {
        let text = descriptionTextForEmptyDataSet(scrollView)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .center
        
        let attributes = [
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body),
            NSAttributedString.Key.foregroundColor: UIColor.lightGray,
            NSAttributedString.Key.paragraphStyle: paragraph
        ]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    //MARK: State Restoration
    enum CodingKeys: String, CodingKey {
        case dataSource = "dataSource"
        case enableSearch = "enableSearch"
    }
    
    override public func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        // TODO: implement this
    }
    
    override public func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }
}


import SINQ

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
    internal let enableSearch: Bool
    
    public required init(artist: Artist, tourSections: Bool, enableSearch: Bool = true) {
        self.artist = artist
        self.tourSections = artist.features.tours && tourSections
        self.enableSearch = enableSearch
        
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
                let regularFont = UIFont.preferredFont(forTextStyle: .body)
                searchController.searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: AppColors.textOnPrimary,
                                                                                 NSAttributedString.Key.font: regularFont], for: .normal)
                let boldFont = regularFont.font(scaledBy: 1.0, withDifferentWeight: .Bold)
                searchController.searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: AppColors.textOnPrimary,
                                                                                 NSAttributedString.Key.font: boldFont], for: .selected)
            }
            // Hide the scope bar for now- we'll reveal it when the user taps on the search field
            searchController.searchBar.showsScopeBar = false
            
            searchController.searchBar.placeholder = self.searchPlaceholder
            searchController.searchBar.barStyle = .black
            searchController.searchBar.isTranslucent = true
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
                self.render()
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
                self.render()
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
                self.render()
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
    
    // This is kind of dumb, but due to some bugs in LayerKit we need to hide the scope bar until the search field is tapped,
    //  otherwise the scope bars show up while pushing/popping this view controller.
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.showsScopeBar = true
    }
    
    //MARK: State Restoration
    enum CodingKeys: String, CodingKey {
        case artist = "artist"
        case tourSections = "tourSections"
        case enableSearch = "enableSearch"
        case sortShows = "sortShows"
    }
    
    override public func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        do {
            let encodedArtist = try JSONEncoder().encode(self.artist)
            coder.encode(encodedArtist, forKey: CodingKeys.artist.rawValue)
            
            coder.encode(tourSections, forKey: CodingKeys.tourSections.rawValue)
            coder.encode(enableSearch, forKey: CodingKeys.enableSearch.rawValue)
            coder.encode(shouldSortShows, forKey: CodingKeys.sortShows.rawValue)
        } catch { }
    }
    
    override public func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }
}

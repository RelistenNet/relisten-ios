//
//  GroupedViewController.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 10/19/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import SINQ
import Siesta
import AsyncDisplayKit

public class GroupedViewController<T>: RelistenTableViewController<[T]>, UISearchResultsUpdating, UISearchBarDelegate {
    public let artist: Artist
    
    var allItems: [T] = []
    private var groupedItems: [Grouping<String, T>] = []
    private var filteredItems: [Grouping<String, T>] = []
    
    let searchController: UISearchController = UISearchController(searchResultsController: nil)
    private let tableUpdateQueue = DispatchQueue(label: "net.relisten.groupedViewController.queue")
    
    public required init(artist: Artist, enableSearch: Bool = true) {
        self.artist = artist
        
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
                let regularFont = UIFont.preferredFont(forTextStyle: .caption1)
                searchController.searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: AppColors.textOnPrimary,
                                                                                 NSAttributedString.Key.font: regularFont], for: .normal)
                let boldFont = regularFont.font(scaledBy: 1.0, withDifferentWeight: .Bold)
                searchController.searchBar.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: AppColors.textOnPrimary,
                                                                                 NSAttributedString.Key.font: boldFont], for: .selected)
            }
            // Hide the scope bar for now- we'll reveal it when the user taps on the search field
            searchController.searchBar.showsScopeBar = false
            
            searchController.searchBar.placeholder = self.searchPlaceholder
            searchController.searchBar.barStyle = .blackTranslucent
            searchController.searchBar.backgroundColor = AppColors.primary
            searchController.searchBar.barTintColor = AppColors.textOnPrimary
            searchController.searchBar.tintColor = AppColors.textOnPrimary
            
            navigationItem.searchController = searchController
            definesPresentationContext = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    //MARK: Subclasses must implement these
    override public var resource: Resource? { get { fatalError("Subclasses must implement resource") } }
    
    func groupNameForItem(_ item: T) -> String { fatalError("Subclasses must implement groupNameForItem") }
    func searchStringMatchesItem(_ item: T, searchText: String) -> Bool { fatalError("Subclasses must override searchStringMatchesItem") }
    func scopeMatchesItem(_ item: T, scope: String) -> Bool { fatalError("Subclasses must override scopeMatchesItem") }
    
    var scopeButtonTitles : [String]? { get { return nil } }
    var searchPlaceholder : String { get { return "Search" } }
    
    func cellNodeBlockForItem(_ item: T) -> ASCellNodeBlock { fatalError("Subclasses must implement cellNodeBlockForItem") }
    func viewControllerForItem(_ item: T) -> UIViewController { fatalError("Subclasses must implement viewControllerForItem") }
    
    //MARK: Refreshing Items
    public override func dataChanged(_ data: [T]) {
        let grouped = sortAndGroupData(data)
        tableUpdateQueue.async {
            self.allItems = data
            self.groupedItems = grouped
            DispatchQueue.main.async {
                self.tableNode.reloadData()
            }
        }
    }
    
    func sortAndGroupData(_ data: [T]) -> [Grouping<String, T>] {
        return sinq(data)
            .groupBy({
                return self.groupNameForItem($0)
            })
            .toArray()
            .sorted(by: { (a, b) -> Bool in
                return a.key <= b.key
            })
    }
    
    func filteredItemsForSearchText(_ searchText: String, scope: String = "All") -> [Grouping<String, T>] {
        return sinq(allItems)
            .filter({ (item) -> Bool in
                return ((scope == "All" || self.scopeMatchesItem(item, scope: scope)) && (searchText == "" || self.searchStringMatchesItem(item, searchText: searchText)))
            })
            .groupBy({
                return self.groupNameForItem($0)
            })
            .toArray()
            .sorted(by: { (a, b) -> Bool in
                return a.key <= b.key
            })
    }
    
    private var curItems : [Grouping<String, T>] {
        get {
            dispatchPrecondition(condition: .onQueue(self.tableUpdateQueue))
            
            if isFiltering() {
                return filteredItems
            } else {
                return groupedItems
            }
        }
    }
    
    func itemForIndexPath(_ indexPath: IndexPath) -> T? {
        dispatchPrecondition(condition: .onQueue(self.tableUpdateQueue))
        
        var retval : T? = nil
        
        let items = curItems
        if indexPath.section >= 0, indexPath.section < items.count {
            let allItems = items[indexPath.section].values
            if indexPath.row >= 0, indexPath.row < allItems.count() {
                retval = allItems.elementAt(indexPath.row)
            }
        }
        return retval
    }
    
    //MARK: Table Data Source
    override public func numberOfSections(in tableNode: ASTableNode) -> Int {
        var count : Int = 0
        tableUpdateQueue.sync {
            count = curItems.count
        }
        return count
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        var count : Int = 0
        tableUpdateQueue.sync {
            let items = curItems
            guard section >= 0, section < items.count else {
                return
            }
            count = items[section].values.count()
        }
        return count
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title : String? = nil
        tableUpdateQueue.sync {
            let items = curItems
            guard section >= 0, section < items.count else {
                return
            }
            title = items[section].key
        }
        return title
    }
    
    override public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        var retval : [String]? = nil
        tableUpdateQueue.sync {
            let items = curItems
            retval = items.map({ return $0.key })
        }
        return retval
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        var retval : ASCellNodeBlock? = nil
        
        tableUpdateQueue.sync {
            if let item = itemForIndexPath(indexPath) {
                retval = cellNodeBlockForItem(item)
            }
        }
        
        if let retval = retval {
            return retval
        } else {
            return { ASCellNode() }
        }
    }
    
    override public func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        var item : T? = nil
        tableUpdateQueue.sync {
            item = itemForIndexPath(indexPath)
        }
        
        if let item = item {
            navigationController?.pushViewController(viewControllerForItem(item), animated: true)
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
        tableUpdateQueue.async {
            self.filteredItems = self.filteredItemsForSearchText(searchTextLC, scope: scope)
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
    
    // This is kind of dumb, but due to some bugs in LayerKit we need to hide the scope bar until the search field is tapped,
    //  otherwise the scope bars show up while pushing/popping this view controller.
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.showsScopeBar = true
    }
}

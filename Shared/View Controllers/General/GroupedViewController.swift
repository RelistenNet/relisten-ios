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
        allItems = data
        groupedItems = sortAndGroupData(allItems)
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
                return (self.scopeMatchesItem(item, scope: scope) && self.searchStringMatchesItem(item, searchText: searchText))
            }).groupBy({
                return self.groupNameForItem($0)
            })
            .toArray()
            .sorted(by: { (a, b) -> Bool in
                return a.key <= b.key
            })
    }
    
    private var curItems : [Grouping<String, T>] { get {
        // TODO: Lock around this
            if isFiltering() {
                return filteredItems
            } else {
                return groupedItems
            }
        }
    }
    
    func itemForIndexPath(_ indexPath: IndexPath) -> T? {
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
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return curItems.count
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        let items = curItems
        guard section >= 0, section < items.count else {
            return 0
        }
        
        return items[section].values.count()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let items = curItems
        guard section >= 0, section < items.count else {
            return nil
        }
        return items[section].key
    }
    
    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        let items = curItems
        return items.map({ return $0.key })
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        if let item = itemForIndexPath(indexPath) {
            return cellNodeBlockForItem(item)
        } else {
            return { ASCellNode() }
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        if let item = itemForIndexPath(indexPath) {
            navigationController?.pushViewController(viewControllerForItem(item), animated: true)
        }
    }
    
    //MARK: Searching
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchController.isActive && (!searchBarIsEmpty() || searchBarScopeIsFiltering)
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        let searchTextLC = searchText.lowercased()
        filteredItems = filteredItemsForSearchText(searchTextLC, scope: scope)
        tableNode.reloadData()
    }

    //MARK: UISearchResultsUpdating
    public func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        if let searchText = searchController.searchBar.text {
            filterContentForSearchText(searchText, scope: scope)
        }
    }
    
    //MARK: UISearchBarDelegate
    public func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

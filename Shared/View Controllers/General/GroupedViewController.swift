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

public class GroupedViewController<ResourceData, T>: RelistenTableViewController<ResourceData> {
    var allItems: [T] = []
    private var groupedItems: [Grouping<String, T>] = []
    private var filteredItems: [Grouping<String, T>] = []
        
    public required init(enableSearch: Bool = true) {
        super.init(useCache: true, refreshOnAppear: true, style: .grouped, enableSearch: enableSearch)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool = false) {
        fatalError("init(useCache:refreshOnAppear:style:enableSearch:) has not been implemented")
    }
    
    //MARK: Subclasses must implement these
    override public var resource: Resource? { get { fatalError("Subclasses must implement resource") } }
    
    func groupNameForItem(_ item: T) -> String { fatalError("Subclasses must implement groupNameForItem") }
    func searchStringMatchesItem(_ item: T, searchText: String) -> Bool { fatalError("Subclasses must override searchStringMatchesItem") }
    func scopeMatchesItem(_ item: T, scope: String) -> Bool { fatalError("Subclasses must override scopeMatchesItem") }

    func cellNodeBlockForItem(_ item: T) -> ASCellNodeBlock { fatalError("Subclasses must implement cellNodeBlockForItem") }
    func viewControllerForItem(_ item: T) -> UIViewController { fatalError("Subclasses must implement viewControllerForItem") }
    
    public func extractShows(_ data: ResourceData) -> [T] {
        if let arr = data as? [T] {
            return arr;
        }
        
        fatalError("overrde this to find [T] from ResourceData")
    }
 
    //MARK: Refreshing Items
    public override func dataChanged(_ data: ResourceData) {
        let items = extractShows(data)
        let grouped = sortAndGroupData(items)
        tableUpdateQueue.async {
            self.allItems = items
            self.groupedItems = grouped
            DispatchQueue.main.async {
                self.render()
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
    override open func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        let searchTextLC = searchText.lowercased()
        tableUpdateQueue.async {
            self.filteredItems = self.filteredItemsForSearchText(searchTextLC, scope: scope)
            DispatchQueue.main.async {
                self.render()
            }
        }
    }
}

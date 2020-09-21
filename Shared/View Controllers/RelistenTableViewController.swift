//
//  RelistenTableViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 3/5/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import SINQ
import Observable
import AsyncDisplayKit
import DZNEmptyDataSet

open class RelistenBaseTableViewController : ASDKViewController<ASDisplayNode>, ASTableDataSource, ASTableDelegate, ResourceObserver {
    public let tableNode: ASTableNode!
    
    public let api = RelistenApi
    
    public var disposal = Disposal()
    
    public init(style: UITableView.Style = .plain) {
        let tableNode = ASTableNode(style: style)
        
        self.tableNode = tableNode

        super.init(node: tableNode)

        self.tableNode.dataSource = self
        self.tableNode.delegate = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .always
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { context in
            self.tableNode.transitionLayout(with: ASSizeRange(min: size, max: size), animated: true, shouldMeasureAsync: true)
        })
    }
    
    // MARK: data handling
    
    public func resourceChanged(_ resource: Resource, event: ResourceEvent) {
        
    }
    
    // MARK: TableView "dataSource" and "delegate"
    open func numberOfSections(in tableNode: ASTableNode) -> Int {
        return 0
    }
    
    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }
    
    open func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    // We can't implement nodeBlockForRowAtIndexPath or nodeForRowAtIndexPath because nodeBlockForRowAtIndexPath always takes precedence, so it prevents subclasses from using that method
    
    open func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    }
    
    open func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
    }
    
    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    open func modelIdentifierForElement(at idx: IndexPath, in tableNode: ASTableNode) -> String? {
        return nil
    }
    open func indexPathForElement(withModelIdentifier identifier: String, in tableNode: ASTableNode) -> IndexPath? {
        return nil
    }
}

open class RelistenTableViewController<TData> : RelistenBaseTableViewController, UISearchResultsUpdating, UISearchBarDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    public let statusOverlay = RelistenResourceStatusOverlay()
    
    open var resource: Resource? { get { return nil } }
    
    public let useCache: Bool
    public var refreshOnAppear: Bool
    public let enableSearch: Bool
    
    open var resultsViewController: UIViewController? { get { return nil } }
    public var searchController: UISearchController! = nil
    public let tableUpdateQueue = DispatchQueue(label: "net.relisten.groupedViewController.queue")

    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool = false) {
        self.useCache = useCache
        self.refreshOnAppear = refreshOnAppear
        self.enableSearch = enableSearch
        
        super.init(style: style)

        searchController = UISearchController(searchResultsController: resultsViewController)

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
        fatalError("just...don't")
    }
    
    open var scopeButtonTitles : [String]? { get { return nil } }
    open var searchPlaceholder : String { get { return "Search" } }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        tableNode.view.emptyDataSetSource = self
        tableNode.view.emptyDataSetDelegate = self
        tableNode.view.tableFooterView = UIView()
        
        if let res = resource {
            res.addObserver(self)
                .addObserver(statusOverlay)
            
            statusOverlay.embed(in: self)
        }
        
        if !refreshOnAppear {
            load()
        }
        
        render()
    }
    
    func load() {
        if useCache {
            let _ = resource?.loadFromCacheThenUpdate()
            if latestData == nil, let res = resource {
                latestData = res.latestData?.typedContent()
            }
            if let latestData = latestData {
                self.dataChanged(latestData)
            }
        }
        else {
            let _ = resource?.load()
        }
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
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        statusOverlay.positionToCoverParent()
    }
    
    private var lastLoadTime: Date? = nil
    
    open override func viewWillAppear(_ animated: Bool) {
        if enableSearch {
            navigationItem.hidesSearchBarWhenScrolling = false
            applySearchBarStyle()
        }
        
        super.viewWillAppear(animated)

        // only do this after 60 minutes
        if let l = lastLoadTime, refreshOnAppear, (Date().timeIntervalSince1970 - l.timeIntervalSince1970) > 60 * 60 {
            // don't hit the cache and then the network--go straight to the network
            LogDebug("---> refreshingOnAppear")
            resource?.load()
        }
        else if lastLoadTime == nil {
            LogDebug("---> performing initial load")
            resource?.load()
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
    
    // MARK: data handling
    
    public var latestData: TData? = nil
    public var previousData: TData? = nil
    
    open func has(oldData old: TData, changed new: TData) -> Bool {
        if let oldArray = old as? [Any], let newArray = new as? [Any] {
            return oldArray.count != newArray.count
        }
        
        return true
    }
    
    open func dataChanged(_ data: TData) {
        render()
    }
    
    open override func resourceChanged(_ resource: Resource, event: ResourceEvent) {
        LogDebug("event: \(event)")
        if case .error = event {
            LogWarn("Error was \(String(describing: resource.latestError))")
        }
        
        if let data: TData = resource.latestData?.typedContent() {
            previousData = latestData
            latestData = data
        }
        
        if previousData == nil && latestData != nil
            || previousData != nil && latestData == nil
            || (previousData != nil && latestData != nil && self.has(oldData: previousData!, changed: latestData!)
            ) {
            LogDebug("---> data changed")
            
            if let d = latestData {
                lastLoadTime = Date()
                dataChanged(d)
            }
            else {
                LogDebug("---> not calling dataChanged because latestData is nil")
            }
        }
    }
    
    // MARK: Layout & Rendering
    
    open func render() {
        LogDebug("[render] calling tableNode.reloadData()")
        self.tableNode.reloadData()
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
        return "Nothing Available"
    }

    public func descriptionTextForEmptyDataSet(_ scrollView: UIScrollView) -> String {
        return ""
    }
    
    public func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return descriptionTextForEmptyDataSet(scrollView).count > 0
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
    
     //MARK: Searching
     public func searchBarIsEmpty() -> Bool {
         return searchController.searchBar.text?.isEmpty ?? true
     }
     
     public func isFiltering() -> Bool {
         let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
         return (searchController.isActive && !searchBarIsEmpty()) || searchBarScopeIsFiltering
     }
     
     open func filterContentForSearchText(_ searchText: String, scope: String = "All") {
         fatalError("this must be overriden if you have enableSearch = true")
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
}

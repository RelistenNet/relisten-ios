//
//  RelistenTableViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 3/5/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import Reachability
import LayoutKit
import SINQ
import Observable

fileprivate let reachability = Reachability()!

public class RelistenReloadableViewLayoutAdapter : ReloadableViewLayoutAdapter {
    internal weak var relistenTableView: RelistenBaseTableViewController?
    
    public init(tableView: RelistenBaseTableViewController, reloadableView: ReloadableView) {
        relistenTableView = tableView
        
        super.init(reloadableView: reloadableView)
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        let cell2 = relistenTableView?.tableView(tableView, cell: cell, forRowAt: indexPath)
        
        cell2?.backgroundColor = relistenTableView?.cellDefaultBackgroundColor

        return cell2 ?? cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        relistenTableView?.tableView(tableView, didSelectRowAt: indexPath)
    }
    
    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return relistenTableView?.sectionIndexTitles(for: tableView)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        relistenTableView?.isCurrentlyScrolling = true
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        relistenTableView?.isCurrentlyScrolling = false
        
        relistenTableView?.renderAfterScrollingIfNeeded()
    }
}

public class RelistenBaseTableViewController : UIViewController, ResourceObserver {
    internal var tableView: UITableView!
    internal var reloadableViewLayoutAdapter: RelistenReloadableViewLayoutAdapter!
    
    internal let api = RelistenApi
    
    internal var isCurrentlyScrolling: Bool = false
    internal var needsRenderAfterScrollingFinishes: Bool = false
    
    internal var tableViewStyle: UITableViewStyle
    internal var cellDefaultBackgroundColor: UIColor = UIColor.clear
    
    internal var disposal = Disposal()

    public init(style: UITableViewStyle = .plain) {
        tableViewStyle = style
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
        }

        tableView = UITableView(frame: view.bounds, style: tableViewStyle)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        reloadableViewLayoutAdapter = RelistenReloadableViewLayoutAdapter(tableView: self, reloadableView: tableView)
        
        tableView.dataSource = reloadableViewLayoutAdapter
        tableView.delegate = reloadableViewLayoutAdapter
        
        view.addSubview(tableView)
    }
    
    // MARK: data handling
    
    public func resourceChanged(_ resource: Resource, event: ResourceEvent) {
        
    }
    
    // MARK: Layout & Rendering
    
    internal func layout(width: CGFloat? = nil, synchronous: Bool = false, batchUpdates: BatchUpdates? = nil, layout: @escaping () -> [Section<[Layout]>]) {
        var w = width
        if w == nil {
            w = tableView.frame.width
        }
        
        reloadableViewLayoutAdapter.reload(width: w, synchronous: synchronous, batchUpdates: batchUpdates, layoutProvider: layout)
    }
    
    public func renderAfterScrollingIfNeeded() {
        
    }
    
    // MARK: TableView "dataSource" and "delegate"
    
    public func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    
    
    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }
}

public class RelistenTableViewController<TData> : RelistenBaseTableViewController {
    internal let statusOverlay = RelistenResourceStatusOverlay()
    
    internal var resource: Resource? { get { return nil } }
    
    public let useCache: Bool
    public var refreshOnAppear: Bool
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        self.useCache = useCache
        self.refreshOnAppear = refreshOnAppear

        super.init(style: style)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("just...don't")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let res = resource {
            res.addObserver(self)
                .addObserver(statusOverlay)
            
            statusOverlay.embed(in: self)
        }
        
        if !refreshOnAppear {
            load()
        }
        
        if useCache, let res = resource {
            latestData = res.latestData?.typedContent()
        }

        render()
    }
    
    func load() {
        if useCache {
            let _ = resource?.loadFromCacheThenUpdate()
        }
        else {
            let _ = resource?.load()
        }
    }
    
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        render()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        statusOverlay.positionToCoverParent()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if refreshOnAppear {
            load()
        }
    }
    
    // MARK: data handling
    
    public var latestData: TData? = nil
    public var previousData: TData? = nil
    
    public func has(oldData: TData, changed: TData) -> Bool {
        return true
    }

    public override func resourceChanged(_ resource: Resource, event: ResourceEvent) {
        print("event: \(event)")
        
        if let data: TData = resource.latestData?.typedContent() {
            previousData = latestData
            latestData = data
        }

        if previousData == nil && latestData != nil
            || previousData != nil && latestData == nil
            || (previousData != nil && latestData != nil && self.has(oldData: previousData!, changed: latestData!)
            ) {
            print("---> data changed")
            render()
        }
    }
    
    // MARK: Layout & Rendering
    
    public override func renderAfterScrollingIfNeeded() {
        if needsRenderAfterScrollingFinishes {
            needsRenderAfterScrollingFinishes = false
            
            render()
        }
    }
    
    public func render() {
        guard isCurrentlyScrolling == false else {
            needsRenderAfterScrollingFinishes = true
            
            return
        }
        
        if let data = latestData {
            print("calling render(forData:)")
            render(forData: data)
        }
        else {
            renderForNoData()
        }
    }
    
    public func render(forData: TData) {
        // override this!
    }
    
    public func renderForNoData() {
        layout { () -> [Section<[Layout]>] in
            return [Section(header: nil, items: [], footer: nil)]
        }
    }

}

public func LayoutsAsSingleSection(items: [Layout], title: String? = nil) -> Section<[Layout]> {
    return Section(
        header: title != nil ? InsetLayout(
            insets: EdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            sublayout: LabelLayout(text: title!, font: UIFont.preferredFont(forTextStyle: .subheadline))
            ) : nil,
        items: items,
        footer: nil
    )
}

extension Array where Element : Layout {
    func asSection(_ title: String? = nil) -> Section<[Layout]> {
        return LayoutsAsSingleSection(items: self, title: title)
    }
    
    func asTable() -> [Section<[Layout]>] {
        return [self.asSection()]
    }
}

import AsyncDisplayKit

public class RelistenBaseAsyncTableontroller : ASViewController<ASDisplayNode>, ASTableDataSource, ASTableDelegate, ResourceObserver {
    internal let tableNode: ASTableNode!
    
    internal let api = RelistenApi
    
    internal var disposal = Disposal()
    
    public init(style: UITableViewStyle = .plain) {
        let tableNode = ASTableNode(style: style)
        
        self.tableNode = tableNode

        super.init(node: tableNode)

        self.tableNode.dataSource = self
        self.tableNode.delegate = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .always
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { context in
            self.tableNode.transitionLayout(with: ASSizeRange(min: size, max: size), animated: true, shouldMeasureAsync: true)
        })
    }
    
    // MARK: data handling
    
    public func resourceChanged(_ resource: Resource, event: ResourceEvent) {
        
    }
    
    // MARK: TableView "dataSource" and "delegate"
}

public class RelistenAsyncTableController<TData> : RelistenBaseAsyncTableontroller {
    internal let statusOverlay = RelistenResourceStatusOverlay()
    
    internal var resource: Resource? { get { return nil } }
    
    public let useCache: Bool
    public var refreshOnAppear: Bool
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableViewStyle = .plain) {
        self.useCache = useCache
        self.refreshOnAppear = refreshOnAppear
        
        super.init(style: style)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("just...don't")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        statusOverlay.positionToCoverParent()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if refreshOnAppear {
            load()
        }
    }
    
    // MARK: data handling
    
    public var latestData: TData? = nil
    public var previousData: TData? = nil
    
    internal func has(oldData old: TData, changed new: TData) -> Bool {
        return true
    }
    
    internal func dataChanged(_ data: TData) {
        
    }
    
    public override func resourceChanged(_ resource: Resource, event: ResourceEvent) {
        print("event: \(event)")
        
        if let data: TData = resource.latestData?.typedContent() {
            previousData = latestData
            latestData = data
        }
        
        if previousData == nil && latestData != nil
            || previousData != nil && latestData == nil
            || (previousData != nil && latestData != nil && self.has(oldData: previousData!, changed: latestData!)
            ) {
            print("---> data changed")
            dataChanged(latestData!)
            render()
        }
    }
    
    // MARK: Layout & Rendering
    
    public func render() {
        DispatchQueue.main.async {
            print("[render] calling tableNode.reloadData()")
            self.tableNode.reloadData()
        }
    }
}

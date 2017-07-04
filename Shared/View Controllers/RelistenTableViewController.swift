//
//  RelistenTableViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 3/5/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import UIKit

import Siesta
import ReachabilitySwift
import LayoutKit

fileprivate let reachability = Reachability()!

public class RelistenReloadableViewLayoutAdapter : ReloadableViewLayoutAdapter {
    internal let relistenTableView: RelistenBaseTableViewController
    
    public init(tableView: RelistenBaseTableViewController, reloadableView: ReloadableView) {
        relistenTableView = tableView
        
        super.init(reloadableView: reloadableView)
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        return relistenTableView.tableView(tableView, cell: cell, forRowAt: indexPath)
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        relistenTableView.tableView(tableView, didSelectRowAt: indexPath)
    }
}

public class RelistenBaseTableViewController : UIViewController, ResourceObserver {
    internal var tableView: UITableView!
    internal var reloadableViewLayoutAdapter: RelistenReloadableViewLayoutAdapter!
    
    internal let api = RelistenApi
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView(frame: view.bounds, style: .plain)
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
    
    internal func layout(width: CGFloat? = nil, synchronous: Bool = true, layout: @escaping (Void) -> [Section<[Layout]>]) {
        var w = width
        if w == nil {
            w = tableView.frame.width
        }
        
        reloadableViewLayoutAdapter.reload(width: w, synchronous: synchronous, layoutProvider: layout)
    }
    
    // MARK: TableView "dataSource" and "delegate"
    
    public func tableView(_ tableView: UITableView, cell: UITableViewCell, forRowAt indexPath: IndexPath) -> UITableViewCell {
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

public class RelistenTableViewController<TData> : RelistenBaseTableViewController {
    internal let statusOverlay = RelistenResourceStatusOverlay()
    
    internal var resource: Resource? { get { return nil } }
    
    public override init() {
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let res = resource {
            res.addObserver(self)
                .addObserver(statusOverlay)
        }
        
        latestData = resource?.latestData?.typedContent()
        render()
        
        statusOverlay.embed(in: self)
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
        
        let _ = resource?.loadFromCacheThenUpdate()
    }
    
    // MARK: data handling
    
    public var latestData: TData? = nil
    
    public override func resourceChanged(_ resource: Resource, event: ResourceEvent) {
        print("event: \(event)")
        
        if let data: TData = resource.latestData?.typedContent() {
            latestData = data
        }
        
        render()
    }
    
    // MARK: Layout & Rendering
    
    public func render() {
        if let data = latestData {
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

public func LayoutsAsSingleSection(items: Array<Layout>, title: String? = nil) -> Section<[Layout]> {
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

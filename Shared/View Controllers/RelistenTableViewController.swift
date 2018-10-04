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

open class RelistenBaseAsyncTableViewController : ASViewController<ASDisplayNode>, ASTableDataSource, ASTableDelegate, ResourceObserver {
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
}

open class RelistenAsyncTableController<TData> : RelistenBaseAsyncTableViewController {
    public let statusOverlay = RelistenResourceStatusOverlay()
    
    open var resource: Resource? { get { return nil } }
    
    public let useCache: Bool
    public var refreshOnAppear: Bool
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        self.useCache = useCache
        self.refreshOnAppear = refreshOnAppear
        
        super.init(style: style)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("just...don't")
    }
    
    open override func viewDidLoad() {
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
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        statusOverlay.positionToCoverParent()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if refreshOnAppear {
            load()
        }
    }
    
    // MARK: data handling
    
    public var latestData: TData? = nil
    public var previousData: TData? = nil
    
    open func has(oldData old: TData, changed new: TData) -> Bool {
        return true
    }
    
    open func dataChanged(_ data: TData) {
        
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
            dataChanged(latestData!)
            render()
        }
    }
    
    // MARK: Layout & Rendering
    
    open func render() {
        DispatchQueue.main.async {
            LogDebug("[render] calling tableNode.reloadData()")
            self.tableNode.reloadData()
        }
    }
}

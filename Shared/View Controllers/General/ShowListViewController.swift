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

public struct ShowWithSingleSource {
    public let show : Show
    public let source : SourceFull?
    public let artist : ArtistWithCounts?
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
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool = false) {
        fatalError("init(useCache:refreshOnAppear:style:enableSearch:) has not been implemented")
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(withDataSource dataSource: ShowListLazyDataSource, enableSearch: Bool) {
        fatalError("init(withDataSource:enableSearch:) has not been implemented")
    }
    
    public required init(enableSearch: Bool = true) {
        fatalError("init(enableSearch:) has not been implemented")
    }
}

public class NewShowListWrappedArrayViewController<Wrapper, ShowType> :
    NewShowListViewController<Wrapper,
                              ShowListArrayDataSource<Wrapper,
                                                      ShowType,
                                                      ShowListWrappedArrayDataSourceExtractor<Wrapper, ShowType>>
                              >
where ShowType: Show {
    private let strongDataSource: ShowListArrayDataSource<Wrapper, ShowType, ShowListWrappedArrayDataSourceExtractor<Wrapper, ShowType>>
    private let strongExtractor: ShowListWrappedArrayDataSourceExtractor<Wrapper, ShowType>
    
    public required init(
        extractor: ShowListWrappedArrayDataSourceExtractor<Wrapper, ShowType>,
        sort: ShowSorting = .descending,
        tourSections: Bool = true,
        artistSections: Bool = false,
        enableSearch: Bool = true
    ) {
        strongExtractor = extractor
        strongDataSource = ShowListArrayDataSource(extractor: strongExtractor, sort: sort, tourSections: tourSections, artistSections: artistSections)
        super.init(withDataSource: strongDataSource, enableSearch: enableSearch)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool = false) {
        fatalError("init(useCache:refreshOnAppear:style:enableSearch:) has not been implemented")
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(withDataSource dataSource: ShowListArrayDataSource<Wrapper, ShowType, ShowListWrappedArrayDataSourceExtractor<Wrapper, ShowType>>, enableSearch: Bool) {
        fatalError("init(withDataSource:enableSearch:) has not been implemented")
    }
    
    public required init(enableSearch: Bool = true) {
        fatalError("init(enableSearch:) has not been implemented")
    }
}

public class NewShowListArrayViewController<ShowType> :
    NewShowListViewController<[ShowType],
                              ShowListArrayDataSource<[ShowType],
                                                      ShowType,
                                                      ShowListArrayDataSourceDefaultExtractor<ShowType>>
                              >
where ShowType: Show {
    private let strongDataSource: ShowListArrayDataSource<[ShowType], ShowType, ShowListArrayDataSourceDefaultExtractor<ShowType>>
    private let strongExtractor: ShowListArrayDataSourceDefaultExtractor<ShowType>
    
    public required init(
        providedArtist artist: ArtistWithCounts? = nil,
        sort: ShowSorting = .descending,
        tourSections: Bool = true,
        artistSections: Bool = false,
        enableSearch: Bool = true
    ) {
        strongExtractor = ShowListArrayDataSourceDefaultExtractor(providedArtist: artist)
        strongDataSource = ShowListArrayDataSource(extractor: strongExtractor, sort: sort, tourSections: tourSections, artistSections: artistSections)
        super.init(withDataSource: strongDataSource, enableSearch: enableSearch)
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool = false) {
        fatalError("init(useCache:refreshOnAppear:style:enableSearch:) has not been implemented")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(withDataSource dataSource: ShowListArrayDataSource<[ShowType], ShowType, ShowListArrayDataSourceDefaultExtractor<ShowType>>, enableSearch: Bool) {
        fatalError("init(withDataSource:enableSearch:) has not been implemented")
    }
    
    public required init(enableSearch: Bool = true) {
        fatalError("init(enableSearch:) has not been implemented")
    }
}

public class NewShowListViewController<T, DataSource: ShowListDataSource> : RelistenTableViewController<T> where DataSource.DataType == T {
    internal weak var dataSource: DataSource? = nil
    
    public required init(withDataSource dataSource: DataSource, enableSearch: Bool = true) {
        self.dataSource = dataSource
        
        super.init(useCache: true, refreshOnAppear: true, style: .plain, enableSearch: enableSearch)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain, enableSearch: Bool = false) {
        fatalError("init(useCache:refreshOnAppear:style:enableSearch:) has not been implemented")
    }
    
    public required init(enableSearch: Bool = true) {
        fatalError("init(enableSearch:) has not been implemented")
    }
    
    // MARK: Subclass Overrides
    public override var resource: Resource? { get { return nil } }
    
    public func layout(show: ShowWithSingleSource, atIndex: IndexPath) -> ASCellNodeBlock {
        return { ShowCellNode(show: show.show) }
    }
    
    override open var scopeButtonTitles : [String]? { get { return ["All", "SBD"] } }
    override open var searchPlaceholder : String { get { return "Filter" } }
    
    func scopeMatchesItem(_ item: T, scope: String) -> Bool {
        // return fale to force a call to filteredItemsForSearchText to delegate to the datasource
        return false
    }
    
    func cellNodeBlockForItem(_ item: T) -> ASCellNodeBlock { fatalError("Subclasses must implement cellNodeBlockForItem") }
    func viewControllerForItem(_ item: T) -> UIViewController { fatalError("Subclasses must implement viewControllerForItem") }
    
    // MARK: Updating Data
    
    public override func dataChanged(_ data: T) {
        guard let ds = dataSource else { return }

        tableUpdateQueue.sync {
            ds.showListDataChanged(data)
        }
        
        super.dataChanged(data)
    }
    
    // MARK: Table Data Source
    override public func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        guard let ds = dataSource else { return }
        
        var show: ShowWithSingleSource? = nil
        let filtering = isFiltering()
        tableUpdateQueue.sync {
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
        tableUpdateQueue.sync {
            count = ds.numberOfSections(whileFiltering: filtering)
        }
        return count
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        guard let ds = dataSource else { return 0 }

        var count : Int = 0
        let filtering = isFiltering()
        tableUpdateQueue.sync {
            count = ds.numberOfShows(in: section, whileFiltering: filtering)
        }
        return count
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let ds = dataSource else { return nil }

        var title : String? = nil
        let filtering = isFiltering()
        tableUpdateQueue.sync {
            title = ds.title(forSection: section, whileFiltering: filtering)
        }
        return title
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        guard let ds = dataSource else { return { ASCellNode() } }

        var retval : ASCellNodeBlock? = nil
        
        let filtering = isFiltering()
        tableUpdateQueue.sync {
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
    override open func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        guard let ds = dataSource else { return }

        ds.showListFilterTextChanged(searchText, inScope: scope)
    }
    
    // MARK: DZNEmptyDataSetSource
    public override func titleTextForEmptyDataSet(_ scrollView: UIScrollView) -> String {
        return "Nothing Available"
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

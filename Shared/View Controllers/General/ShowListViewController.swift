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

public class ShowListViewController<T> : RelistenTableViewController<T> {
    internal let artist: Artist
    internal let showsResource: Resource?
    internal let tourSections: Bool
    
    var shouldSortShows : Bool = true
    
    public required init(artist: Artist, showsResource: Resource?, tourSections: Bool) {
        self.artist = artist
        self.showsResource = showsResource
        self.tourSections = artist.features.tours && tourSections
        
        super.init(useCache: true, refreshOnAppear: true)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(useCache: Bool, refreshOnAppear: Bool, style: UITableView.Style = .plain) {
        fatalError("init(useCache:refreshOnAppear:) has not been implemented")
    }
    
    public override var resource: Resource? { get { return showsResource } }
    
    public func extractShowsAndSource(forData: T) -> [ShowWithSingleSource] {
        fatalError("need to override this")
    }
    
    public override func has(oldData: T, changed: T) -> Bool {
        let x1 = extractShowsAndSource(forData: oldData)
        let x2 = extractShowsAndSource(forData: changed)
        
        return x1.count != x2.count
    }
    
    public override func render() {
        showMappingQueue.sync {
            rebuildShowMappings()
        }
        super.render()
    }
    
    // MARK: Relayout
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         trackFinishedHandler = RelistenDownloadManager.shared.eventTrackFinishedDownloading.addHandler(target: self, handler: ShowListViewController<T>.relayoutIfContainsTrack)
         tracksDeletedHandler = RelistenDownloadManager.shared.eventTracksDeleted.addHandler(target: self, handler: ShowListViewController<T>.relayoutIfContainsTracks)
         */
    }
    
    public func layout(show: Show, atIndex: IndexPath) -> ASCellNodeBlock {
        return { ShowCellNode(show: show) }
    }

    func relayoutIfContainsTrack(_ track: Track) {
        showMappingQueue.sync {
            rebuildShowMappings()
            
//            if let showsWithSources = showsWithSources {
//                if sinq(showsWithSources).any({ $0.show.id == track.showInfo.show.id }) {
//                    render()
//                }
//            }
        }
    }

    func relayoutIfContainsTracks(_ tracks: [Track]) {
        showMappingQueue.sync {
            rebuildShowMappings()
            
//            if let showsWithSources = showsWithSources {
//                let trackShowsId = tracks.map({ $0.showInfo.show.id })
//            
//                if sinq(showsWithSources).any({ trackShowsId.contains($0.show.id) }) {
//                    render()
//                }
//            }
        }
    }
    
    // MARK: Preparing Show Info for the DataSource
    internal var showsByTour: [(tourName: String?, showWithSource: [ShowWithSingleSource])]?
    internal var showMapping: [IndexPath: ShowWithSingleSource]?
    internal var showsWithSources: [ShowWithSingleSource]?
    
    internal let showMappingQueue = DispatchQueue(label: "live.relisten.ShowListViewController.mappingQueue")
    
    private func rebuildShowMappings() {
        dispatchPrecondition(condition: .onQueue(showMappingQueue))
        if let d = latestData {
            let extractedShows = extractShowsAndSource(forData: d)
            if artist.shouldSortYearsDescending, self.shouldSortShows {
                showsWithSources = extractedShows.sorted(by: { (showA, showB) in
                    return (showA.show.date.timeIntervalSince(showB.show.date) > 0)
                })
            } else {
                showsWithSources = extractedShows
            }
            buildShowMappingAndTourSections()
        }
    }
    
    private func buildShowMappingAndTourSections() {
        dispatchPrecondition(condition: .onQueue(showMappingQueue))
        guard let showsWithSources = showsWithSources else {
            return
        }
        
        var sectionCount = 0
        
        showMapping = [:]
        if tourSections {
            showsByTour = []
        }
        
        var currentSection: [ShowWithSingleSource] = []
        
        for (idx, showWithSource) in showsWithSources.enumerated() {
            if idx == 0 {
                let idxP = IndexPath(row: 0, section: 0)
                
                currentSection.append(showWithSource)
                showMapping?[idxP] = showWithSource
            }
            else {
                if tourSections {
                    let prevShowWithSource = showsWithSources[idx - 1]
                    
                    if prevShowWithSource.show.tour_id != showWithSource.show.tour_id {
                        showsByTour?.append((prevShowWithSource.show.tour?.name, currentSection))
                        sectionCount += 1
                        
                        currentSection = []
                    }
                }
                
                let idxP = IndexPath(row: currentSection.count, section: sectionCount)
                showMapping?[idxP] = showWithSource
                currentSection.append(showWithSource)
            }
            
            if tourSections {
                if idx == showsWithSources.count - 1 {
                    showsByTour?.append((showWithSource.show.tour?.name, currentSection))
                }
            }
        }
    }
    
    private func showWithSource(at indexPath : IndexPath) -> ShowWithSingleSource? {
        var showWithSource : ShowWithSingleSource?
        
        showMappingQueue.sync {
            if showsWithSources == nil {
                rebuildShowMappings()
            }
            
            showWithSource = showMapping?[indexPath]
        }
        
        return showWithSource
    }
    
    private func numberOfSections() -> Int {
        var retval : Int = 1
        showMappingQueue.sync {
            if showsWithSources == nil {
                rebuildShowMappings()
            }
            
            if tourSections, let r = showsByTour?.count {
                retval = r
            }
        }
        return retval
    }
    
    private func numberOfRows(in section : Int) -> Int {
        var retval : Int = 0
        showMappingQueue.sync {
            if showsWithSources == nil {
                rebuildShowMappings()
            }
            
            if tourSections, section >= 0, section < showsByTour?.count ?? 0 {
                if let r = showsByTour?[section].showWithSource.count {
                    retval = r
                }
            } else if let r = showsWithSources?.count {
                retval = r
            }
        }
        return retval
    }
    
    private func nodeBlockForRow(at indexPath: IndexPath) -> ASCellNodeBlock {
        var showWithSource : ShowWithSingleSource?
        showMappingQueue.sync {
            if showsWithSources == nil {
                rebuildShowMappings()
            }
            
            if tourSections,
               indexPath.section >= 0, indexPath.section < showsByTour?.count ?? 0,
               indexPath.row >= 0, indexPath.row < showsByTour?[indexPath.section].showWithSource.count ?? 0 {
                showWithSource = showsByTour?[indexPath.section].showWithSource[indexPath.row]
            } else {
                showWithSource = showsWithSources?[indexPath.row]
            }
        }
        assert(!(showWithSource == nil), "Couldn't find a show for index path \(indexPath) with tour sections = \(tourSections)")
        return layout(show: showWithSource!.show, atIndex: indexPath)
     }
    
    private func titleForHeader(in section: Int) -> String? {
        var title : String?
        showMappingQueue.sync {
            if showsWithSources == nil {
                rebuildShowMappings()
            }
            
            if tourSections,
               section >= 0, section < showsByTour?.count ?? 0,
               let tourName = showsByTour?[section].tourName {
                title = tourName
            }
        }
        return title
    }
    
    // MARK: Table Data Source
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        if let showWithSource = showWithSource(at: indexPath) {
            let sourcesViewController = SourcesViewController(artist: artist, show: showWithSource.show)
            sourcesViewController.presentIfNecessary(navigationController: navigationController, forSource: showWithSource.source)
        }
    }
    
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return numberOfSections()
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return numberOfRows(in: section)
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return nodeBlockForRow(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleForHeader(in: section)
    }
}

//
//  ManageOfflineMusicNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Observable

public class ManageOfflineMusicNode : ASCellNode {
    var disposal = Disposal()
    weak var myViewController : UIViewController?
    
    public init(viewController : UIViewController? = nil) {
        myViewController = viewController
        
        downloadStatsNode = ASTextNode("0 tracks saved offline (0 bytes)", textStyle: .body)
        
        deleteAllDownloadsNode = ASButtonNode()
        deleteAllDownloadsNode.setTitle("Delete all downloaded tracks »", with: UIFont.preferredFont(forTextStyle: .body), with: UIColor.flatRed(), for: .normal)
        deleteAllDownloadsNode.setTitle("No tracks to delete", with: UIFont.preferredFont(forTextStyle: .body), with: AppColors.mutedText, for: .disabled)
        deleteAllDownloadsNode.isEnabled = false
        
        dbOfflineTrackCount = MyLibrary.shared.offline.tracks.filter("state >= %d", OfflineTrackState.downloaded.rawValue).count
        dbOfflineTrackSize = 0
        realOfflineTrackSize = 0
        realOfflineTrackCount = 0
        
        super.init()
        
        deleteAllDownloadsNode.addTarget(self, action: #selector(deleteButtonPressed(_:)), forControlEvents: .touchUpInside)
        
        MyLibrary.shared.offline.tracks.filter("state >= %d", OfflineTrackState.downloaded.rawValue).observeWithValue { [weak self] (tracks, changes) in
            guard let s = self else { return }
            
            s.dbOfflineTrackCount = tracks.count
            MyLibrary.shared.diskUsageForAllTracks() { (diskUsage, numberOfTracks) in
                s.dbOfflineTrackSize = diskUsage
            }
        }.dispose(to: &disposal)
        
        // Perform an expensive disk size check at launch time just to make sure there aren't any inconsistencies with the database
        MyLibrary.shared.realDiskUsageForAllTracks { [weak self] (diskUsage, numberOfTracks) in
            guard let s = self else { return }
            s.realOfflineTrackSize = diskUsage
            s.realOfflineTrackCount = numberOfTracks
        }
        
        automaticallyManagesSubnodes = true
        accessoryType = .none
    }
    
    var dbOfflineTrackCount : Int {
        didSet {
            self.updateDownloadStatsString()
        }
    }
    var realOfflineTrackCount : Int {
        didSet {
            self.updateDownloadStatsString()
        }
    }
    var offlineTrackCount : Int {
        return (realOfflineTrackCount > dbOfflineTrackCount) ? realOfflineTrackCount : dbOfflineTrackCount
    }
    
    var dbOfflineTrackSize : UInt64 {
        didSet {
            self.updateDownloadStatsString()
        }
    }
    var realOfflineTrackSize : UInt64 {
        didSet {
            self.updateDownloadStatsString()
        }
    }
    var offlineTrackSize : UInt64 {
        return (realOfflineTrackSize > dbOfflineTrackSize) ? realOfflineTrackSize : dbOfflineTrackSize
    }
    
    func updateDownloadStatsString() {
        DispatchQueue.main.async {
            self.downloadStatsNode.attributedText = RelistenAttributedString("\(self.offlineTrackCount) tracks saved offline (\(self.offlineTrackSize.humanizeBytes()))", textStyle: .body)
            if self.offlineTrackCount == 0 && self.offlineTrackSize == 0 {
                self.deleteAllDownloadsNode.isEnabled = false
            } else {
                self.deleteAllDownloadsNode.isEnabled = true
            }
            self.setNeedsLayout()
        }
    }
    
    @objc func deleteButtonPressed(_ sender: UIButton) {
        let songs = "\(offlineTrackCount) track" + (offlineTrackCount > 1 ? "s" : "")
        
        let alertController = UIAlertController(
            title: "Delete all downloaded tracks?",
            message: "This will delete " + songs +  " and free up \(offlineTrackSize.humanizeBytes())",
            preferredStyle: .actionSheet
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        let destroyAction = UIAlertAction(title: "Delete " + songs, style: .destructive) { (action) in
            DownloadManager.shared.deleteAllDownloads {
                self.dbOfflineTrackSize = 0
                self.dbOfflineTrackCount = 0
                self.realOfflineTrackCount = 0
                self.realOfflineTrackSize = 0
                self.setNeedsLayout()
            }
        }
        alertController.addAction(destroyAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = deleteAllDownloadsNode.view
            popoverController.sourceRect = deleteAllDownloadsNode.view.bounds
        }
        
        self.myViewController?.present(alertController, animated: true)
    }
    
    public let downloadStatsNode : ASTextNode
    public let deleteAllDownloadsNode : ASButtonNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let vert = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 16,
            justifyContent: .center,
            alignItems: .start,
            children: [
                downloadStatsNode,
                deleteAllDownloadsNode
            ]
        )
        vert.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16),
            child: vert
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}

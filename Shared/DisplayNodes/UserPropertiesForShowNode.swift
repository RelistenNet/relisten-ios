//
//  UserPropertiesForShowNode.swift
//  Relisten
//
//  Created by Jacob Farkas on 7/24/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Observable

public class UserPropertiesForShowNode : ASCellNode, FavoriteButtonDelegate {
    public let source: SourceFull
    public let show: ShowWithSources
    public let artist: ArtistWithCounts
    private lazy var completeShowInformation = CompleteShowInformation(source: self.source, show: self.show, artist: self.artist)
    
    private var numberOfDownloadedTracks : Int = 0
    private var sizeOfDownloadedTracks : UInt64 = 0
    
    public var favoriteButtonAccessibilityLabel : String { get { return "Favorite Show" } }
    
    var disposal = Disposal()
    
    private weak var myViewController : UIViewController?
    
    public init(source: SourceFull, inShow show: ShowWithSources, artist: ArtistWithCounts, viewController: UIViewController? = nil) {
        self.source = source
        self.show = show
        self.artist = artist
        self.myViewController = viewController
        
        favoriteButton = FavoriteButtonNode()
        favoriteButton.normalColor = UIColor.black
        
        shareButton = ASButtonNode()
        // TODO: Use a proper share icon
        shareButton.setImage(#imageLiteral(resourceName: "share"), for: .normal)
        shareButton.accessibilityLabel = "Share"
        
        downloadText = ASTextNode("Download", textStyle: .footnote)
        downloadButton = ASButtonNode()
        downloadButton.setImage(#imageLiteral(resourceName: "download-outline"), for: .normal)
        downloadButton.accessibilityLabel = "Download Show"
        
        deleteButton = ASButtonNode()
        deleteButton.setImage(#imageLiteral(resourceName: "delete"), for: .normal)
        deleteButton.isHidden = true
        deleteButton.accessibilityLabel = "Delete Downloaded Show"
        
        super.init()
        
        self.backgroundColor = AppColors.lightGreyBackground
        
        automaticallyManagesSubnodes = true
        accessoryType = .none
        
        favoriteButton.currentlyFavorited = MyLibrary.shared.isFavorite(show: show, byArtist: artist)
        favoriteButton.delegate = self
        shareButton.addTarget(self, action:#selector(presentShareSheet), forControlEvents:.touchUpInside)
        downloadButton.addTarget(self, action:#selector(downloadToggled), forControlEvents:.touchUpInside)
        deleteButton.addTarget(self, action:#selector(deletePressed), forControlEvents:.touchUpInside)
        
        DispatchQueue.main.async {
            self.setupLibraryObservers()
        }
    }
    
    public let favoriteButton : FavoriteButtonNode
    public let shareButton : ASButtonNode
    public var downloadText : ASTextNode
    public let downloadButton : ASButtonNode
    public let deleteButton : ASButtonNode
    
    public func didFavorite(currentlyFavorited : Bool) {
        if currentlyFavorited {
            MyLibrary.shared.favoriteSource(show: self.completeShowInformation)
        } else {
            let _ = MyLibrary.shared.unfavoriteSource(show: self.completeShowInformation)
        }
    }
    
    @objc public func presentShareSheet() {
        let shareVc = ShareHelper.shareViewController(forSource: completeShowInformation)
        
        if let popoverController = shareVc.popoverPresentationController {
            popoverController.sourceView = shareButton.view
            popoverController.sourceRect = shareButton.view.bounds
        }
        
        if RelistenApp.sharedApp.playbackController.hasBarBeenAdded {
            RelistenApp.sharedApp.playbackController.viewController.present(shareVc, animated: true, completion: nil)
        }
        else {
            self.myViewController?.present(shareVc, animated: true, completion: nil)
        }
    }
    
    @objc public func downloadToggled() {
        let _ = DownloadManager.shared.download(show: self.completeShowInformation)
    }
    
    @objc public func deletePressed() {
        let songs = "\(numberOfDownloadedTracks) song" + (numberOfDownloadedTracks > 1 ? "s" : "")
        
        let alertController = UIAlertController(
            title: "Delete all downloaded tracks?",
            message: "This will delete " + songs +  " and free up \(sizeOfDownloadedTracks.humanizeBytes())",
            preferredStyle: .actionSheet
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        let destroyAction = UIAlertAction(title: "Delete " + songs, style: .destructive) { (action) in
            DownloadManager.shared.delete(showInfo: self.completeShowInformation)
            self.deleteButton.isHidden = true
            self.downloadButton.setImage(#imageLiteral(resourceName: "download-outline"), for: .normal)
            self.setNeedsLayout()
        }
        alertController.addAction(destroyAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = deleteButton.view
            popoverController.sourceRect = deleteButton.view.bounds
        }
        
        if RelistenApp.sharedApp.playbackController.hasBarBeenAdded {
            RelistenApp.sharedApp.playbackController.viewController.present(alertController, animated: true, completion: nil)
        }
        else {
            self.myViewController?.present(alertController, animated: true)
        }
    }
    
    private func setupLibraryObservers() {
        let library = MyLibrary.shared
        
        library.favorites.sources.observeWithValue { [weak self] (new, changes) in
            guard let s = self else { return }
            
            s.favoriteButton.currentlyFavorited = library.isFavorite(source: s.source)
        }.dispose(to: &disposal)
        
        library.offline.tracks
            .filter("source_uuid == %@ && state == %d", source.uuid.uuidString, OfflineTrackState.downloaded.rawValue)
            .observeWithValue { [weak self] tracks, changes in
                guard let s = self else { return }
                
                let totalSize: Int = tracks.sum(ofProperty: "file_size")
                let count = tracks.count
                
                s.rebuildOfflineStatus(UInt64(totalSize), numberOfTracks: count)
        }.dispose(to: &disposal)
    }
    
    private func rebuildOfflineStatus(_ sourceSize: UInt64, numberOfTracks: Int) {
        guard sizeOfDownloadedTracks != sourceSize || numberOfDownloadedTracks != numberOfTracks else {
            return
        }
        
        var txt = "Make Show Available Offline"
        var downloadButtonImage : UIImage = #imageLiteral(resourceName: "download-outline")
        var deleteButtonHidden = true
        
        numberOfDownloadedTracks = numberOfTracks
        sizeOfDownloadedTracks = sourceSize
        if numberOfTracks > 0 {
            deleteButtonHidden = false
            let totalNumberOfTracks = source.trackCount
            if numberOfTracks == totalNumberOfTracks {
                downloadButtonImage = #imageLiteral(resourceName: "download-complete")
                txt = "All \(numberOfTracks) songs downloaded (\(sourceSize.humanizeBytes()))"
            } else {
                txt = "\(numberOfTracks)/\(totalNumberOfTracks) song" + (totalNumberOfTracks > 1 ? "s" : "") + " (\(sourceSize.humanizeBytes()))"
            }
        }
        
        deleteButton.isHidden = deleteButtonHidden
        downloadButton.setImage(downloadButtonImage, for: .normal)
        
        downloadText = ASTextNode(txt, textStyle: .footnote, color: .darkGray, alignment: .center)
        downloadText.maximumNumberOfLines = 0
        downloadText.style.alignSelf = .stretch
        downloadText.style.flexGrow = 1.0
        
        self.clipsToBounds = false;
        
        DispatchQueue.main.async { self.setNeedsLayout() }
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let buttonBar = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(
                favoriteButton,
                SpacerNode(),
                downloadButton,
                deleteButton.isHidden ? nil : deleteButton,
                SpacerNode(),
                shareButton
            )
        )
        buttonBar.style.alignSelf = .stretch
        
        let vert = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: ArrayNoNils(
                numberOfDownloadedTracks > 0 ? downloadText : nil,
                buttonBar
            )
        )
        vert.style.alignSelf = .stretch

        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            child: vert
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}

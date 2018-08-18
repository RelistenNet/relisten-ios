//
//  DownloadProgressNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/10/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import UIKit
import DownloadButton

public protocol DownloadProgressActions {
    var state : Track.DownloadState { get set }
    func updateProgress(_ progress : Float)
}

public protocol DownloadProgressDelegate : class {
    func downloadButtonTapped()
}

func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
}

public class DownloadProgressNode : ASDisplayNode {
    private static let buttonSize: CGFloat = 16
    private static var buttonImage = {
        return resizeImage(image: #imageLiteral(resourceName: "download-complete"), newWidth: DownloadProgressNode.buttonSize * 3.0)
    }()

    public let downloadProgressNode: ASDisplayNode
    public weak var delegate : DownloadProgressDelegate? = nil
    
    public var state : Track.DownloadState = .none {
        didSet {
            if let button = downloadProgressNode.view as? PKDownloadButton {
                let blockState = state
                DispatchQueue.main.async {
                    switch blockState {
                    case .none:
                        button.state = .startDownload
                    case .queued:
                        button.state = .pending
                    case .downloading:
                        button.state = .downloading
                    case .downloaded:
                        button.state = .downloaded
                    }
                }
            }
        }
    }
    
    public override init() {
        downloadProgressNode = ASDisplayNode(viewBlock: { PKDownloadButton(frame: CGRect(x: 0, y: 0, width: DownloadProgressNode.buttonSize, height: DownloadProgressNode.buttonSize)) })
        
        super.init()
        
        automaticallyManagesSubnodes = true
    }
    
    public convenience init(delegate: DownloadProgressDelegate) {
        self.init()
        self.delegate = delegate
    }
    
    public override func didLoad() {
        super.didLoad()
        
        if let button = downloadProgressNode.view as? PKDownloadButton {
            button.delegate = self
            
            button.backgroundColor = UIColor.clear
            
            button.downloadedButton.cleanDefaultAppearance()
            button.downloadedButton.tintColor = AppColors.primary
            button.downloadedButton.setImage(DownloadProgressNode.buttonImage, for: .normal)
            button.downloadedButton.setTitleColor(AppColors.primary, for: .normal)
            button.downloadedButton.setTitleColor(AppColors.highlight, for: .highlighted)
            
            button.stopDownloadButton.tintColor = AppColors.primary
            button.stopDownloadButton.filledLineStyleOuter = true
            
            button.pendingView.tintColor = AppColors.primary
            button.pendingView.radius = (CGFloat(DownloadProgressNode.buttonSize) - (2.0 * button.pendingView.lineWidth)) / 2.0
            
            button.startDownloadButton.cleanDefaultAppearance()
            button.startDownloadButton.setImage(#imageLiteral(resourceName: "download-outline"), for: .normal)
            button.startDownloadButton.tintColor = AppColors.primary
            button.stopDownloadButton.radius = (CGFloat(DownloadProgressNode.buttonSize) - (2.0 * button.pendingView.lineWidth)) / 2.0
            button.stopDownloadButton.stopButtonWidth = 4.0
            button.stopDownloadButton.filledLineWidth = 1.5
        }
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        downloadProgressNode.style.layoutPosition = CGPoint(x: 0, y: 0)
        downloadProgressNode.style.preferredSize = CGSize(width: DownloadProgressNode.buttonSize, height: DownloadProgressNode.buttonSize)
        
        return ASAbsoluteLayoutSpec(
            sizing: ASAbsoluteLayoutSpecSizing.sizeToFit,
            children: [ downloadProgressNode ]
        )
    }
}

extension DownloadProgressNode : DownloadProgressActions {
    // MARK: DownloadProgressActions
    public func updateProgress(_ progress : Float) {
        if let button = downloadProgressNode.view as? PKDownloadButton {
            DispatchQueue.main.async {
                button.stopDownloadButton.progress = CGFloat(progress)
            }
        }
    }
}

extension DownloadProgressNode : PKDownloadButtonDelegate {
    // MARK: PKDownloadButtonDelegate
    public func downloadButtonTapped(_ downloadButton: PKDownloadButton!, currentState state: PKDownloadButtonState) {
        self.delegate?.downloadButtonTapped()
    }
}

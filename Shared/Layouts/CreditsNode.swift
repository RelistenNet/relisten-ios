//
//  CreditsNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation

import AsyncDisplayKit
import SafariServices

public class CreditsNode : ASCellNode {
    private weak var myViewController : UIViewController?
    
    public init(viewController : UIViewController? = nil) {
        myViewController = viewController
        
        appIconNode = ASImageNode()
        appIconNode.image = RelistenApp.sharedApp.appIcon
        appIconNode.cornerRadius = 13 // eh...close enough
        appIconNode.style.maxWidth = .init(unit: .points, value: 60)
        appIconNode.style.maxHeight = .init(unit: .points, value: 60)
        appIconNode.style.preferredSize = CGSize(width: appIconNode.style.maxWidth.value, height: appIconNode.style.maxHeight.value)
        appIconNode.style.flexShrink = 1.0
        
        appNameNode = ASTextNode(RelistenApp.sharedApp.appName, textStyle: .headline)
        appVersionNode = ASTextNode("Version \(RelistenApp.sharedApp.appVersion)", textStyle: .caption1)
        appBuildVersionNode = ASTextNode(" (build \(RelistenApp.sharedApp.appBuildVersion))", textStyle: .caption1, color: AppColors.mutedText)
        
        peopleCreditsNode = ASTextNode()
        
        super.init()
        
        self.setupPeopleCreditsNode()
        
        automaticallyManagesSubnodes = true
        accessoryType = .none
    }
    
    public let appIconNode : ASImageNode
    public let appNameNode : ASTextNode
    public let appVersionNode : ASTextNode
    public let appBuildVersionNode : ASTextNode
    
    public let peopleCreditsNode : ASTextNode
    private func setupPeopleCreditsNode() {
        let attributedString : NSMutableAttributedString = NSMutableAttributedString(string: "\(RelistenApp.sharedApp.appName) was written by Alec Gorge\nWith help from\nJacob Farkas\nDaniel Saewitz")
        
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let boldFontDescriptor = fontDescriptor.withSymbolicTraits(.traitBold)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 3.0
        
        let fullStringAttributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey.font : UIFont(descriptor: fontDescriptor, size: 0.0),
                                                                   NSAttributedStringKey.paragraphStyle : paragraphStyle]
        
        attributedString.setAttributes(fullStringAttributes, range: NSMakeRange(0, attributedString.string.count))
        
        let linkAttributes : [NSAttributedStringKey : Any] = [NSAttributedStringKey.foregroundColor : AppColors.primary,
                                                              NSAttributedStringKey.font : UIFont(descriptor: boldFontDescriptor!, size: 0.0),
                                                              // For some reason underlineStyle isn't being respected, so I'm just setting the underline to clear
                                                              NSAttributedStringKey.underlineColor : UIColor.clear,
                                                              NSAttributedStringKey.underlineStyle : NSUnderlineStyle.styleNone.rawValue]
        
        attributedString.addLink(link: URL(string: "https://alecgorge.com")!, string: "Alec Gorge", attributes: linkAttributes)
        attributedString.addLink(link: URL(string: "https://rkas.net")!, string: "Jacob Farkas", attributes: linkAttributes)
        attributedString.addLink(link: URL(string: "https://saewitz.com")!, string: "Daniel Saewitz", attributes: linkAttributes)
        
        peopleCreditsNode.attributedText = attributedString
        peopleCreditsNode.delegate = self
        peopleCreditsNode.isUserInteractionEnabled = true
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let versionText = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 0,
            justifyContent: .center,
            alignItems: .center,
            children: [
                appVersionNode,
                appBuildVersionNode
            ]
        )
        versionText.style.alignSelf = .stretch
        
        let appHeader = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 10,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [
                appIconNode,
                appNameNode,
                versionText,
                peopleCreditsNode
            ]
        )
        appHeader.style.alignSelf = .stretch
        
        let vert = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .start,
            children: [
                appHeader
            ]
        )
        vert.style.alignSelf = .stretch
        
        let l = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 40, left: 0, bottom: 40, right: 0),
            child: vert
        )
        l.style.alignSelf = .stretch
        
        return l
    }
}

extension CreditsNode : ASTextNodeDelegate {
    public func textNode(_ textNode: ASTextNode!, tappedLinkAttribute attribute: String!, value: Any!, at point: CGPoint, textRange: NSRange) {
        if let url = value as! URL? {
            myViewController?.navigationController?.present(SFSafariViewController(url: url), animated: true, completion: nil)
        }
    }
}

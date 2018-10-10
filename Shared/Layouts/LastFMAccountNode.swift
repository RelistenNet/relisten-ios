//
//  LastFMAccountNode.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/28/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Observable

public class LastFMAccountNode : ASCellNode {
    private weak var myViewController : UIViewController?
    
    var disposal = Disposal()
    public init(viewController : UIViewController? = nil) {
        myViewController = viewController
        
        lastFMLogoNode = ASImageNode()
        lastFMLogoNode.image = UIImage(named: "lastFM-logo")
        lastFMLogoNode.style.maxHeight = .init(unit: .points, value: 25.2)
        lastFMLogoNode.style.maxWidth = .init(unit: .points, value: 100)
        lastFMLogoNode.style.preferredSize = CGSize(width: lastFMLogoNode.style.maxWidth.value, height: lastFMLogoNode.style.maxHeight.value)
        lastFMLogoNode.style.flexShrink = 1.0
        
        lastFMUsernameLabelNode = ASTextNode("Username: ", textStyle: .body)
        lastFMPasswordLabelNode = ASTextNode("Password: ", textStyle: .body)
        
        lastFMUsernameInputNode = ASEditableTextNode()
        lastFMUsernameInputNode.scrollEnabled = false
        lastFMUsernameInputNode.spellCheckingType = .no
        lastFMUsernameInputNode.autocorrectionType = .no
        lastFMUsernameInputNode.autocapitalizationType = .none
        lastFMUsernameInputNode.maximumLinesToDisplay = 1
        lastFMUsernameInputNode.attributedPlaceholderText = RelistenAttributedString("username", textStyle: .body, color: AppColors.mutedText)
        
        lastFMPasswordInputNode = ASEditableTextNode()
        lastFMPasswordInputNode.scrollEnabled = false
        lastFMUsernameInputNode.spellCheckingType = .no
        lastFMUsernameInputNode.autocorrectionType = .no
        lastFMUsernameInputNode.autocapitalizationType = .none
        lastFMPasswordInputNode.maximumLinesToDisplay = 1
        lastFMPasswordInputNode.isSecureTextEntry = true
        lastFMPasswordInputNode.textView.isSecureTextEntry = true
        lastFMPasswordInputNode.enablesReturnKeyAutomatically = true
        lastFMPasswordInputNode.attributedPlaceholderText = RelistenAttributedString("password", textStyle: .body, color: AppColors.mutedText)
        
        loginButtonNode = ASButtonNode()
        loginButtonNode.backgroundColor = AppColors.primary
        loginButtonNode.setTitle("Login", with: UIFont.preferredFont(forTextStyle: .body), with: AppColors.textOnPrimary, for: .normal)
        
        loginInfoNode = ASTextNode("Logged in as \(LastFMScrobbler.shared.username ?? "(error)")", textStyle: .body)
        
        super.init()
        
        automaticallyManagesSubnodes = true
        accessoryType = .none
        
        LastFMScrobbler.shared.observeUsername.observe { (username, _) in
            DispatchQueue.main.async {
                self.setupLoggedInNode()
                self.setNeedsLayout()
            }
        }.add(to: &disposal)
        LastFMScrobbler.shared.observeLoggedIn.observe { (current, previous) in
            if (current == previous) { return }
            if current {
                self.loginButtonNode.setTitle("Logout", with: UIFont.preferredFont(forTextStyle: .body), with: AppColors.textOnPrimary, for: .normal)
            } else {
                self.loginButtonNode.setTitle("Login", with: UIFont.preferredFont(forTextStyle: .body), with: AppColors.textOnPrimary, for: .normal)
            }
            self.setNeedsLayout()
        }.add(to: &disposal)

    }
    
    private func setupLoggedInNode() {
        if let username = LastFMScrobbler.shared.username {
            let loggedInString = NSMutableAttributedString(string: "Logged in as \(username)")
            
            let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            let boldFontDescriptor = fontDescriptor.withSymbolicTraits(.traitBold)
            let fullStringAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : UIFont(descriptor: fontDescriptor, size: 0.0)]
            
            loggedInString.setAttributes(fullStringAttributes, range: NSMakeRange(0, loggedInString.string.count))
            
            let linkAttributes : [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor : AppColors.primary,
                                                                  NSAttributedString.Key.font : UIFont(descriptor: boldFontDescriptor!, size: 0.0),
                                                                  // For some reason underlineStyle isn't being respected, so I'm just setting the underline to clear
                                                                  NSAttributedString.Key.underlineColor : UIColor.clear,
                                                                  NSAttributedString.Key.underlineStyle : []]
            
            loggedInString.addLink(link: URL(string: "http://last.fm/user/\(username)")!, string: username, attributes: linkAttributes)
            
            self.loginInfoNode.attributedText = loggedInString
        }
    }
    
    let lastFMLogoNode : ASImageNode
    
    let loginInfoNode : ASTextNode
    
    let lastFMUsernameLabelNode : ASTextNode
    let lastFMUsernameInputNode : ASEditableTextNode
    
    let lastFMPasswordLabelNode : ASTextNode
    let lastFMPasswordInputNode : ASEditableTextNode
    
    let loginButtonNode : ASButtonNode
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var username : ASStackLayoutSpec? = nil
        var password : ASStackLayoutSpec? = nil
        
        if LastFMScrobbler.shared.isLoggedIn == false {
            username = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 4,
                justifyContent: .start,
                alignItems: .stretch,
                children: [
                    lastFMUsernameLabelNode,
                    lastFMUsernameInputNode
                ]
            )
            username?.style.alignSelf = .stretch
            
            password = ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 4,
                justifyContent: .start,
                alignItems: .stretch,
                children: [
                    lastFMPasswordLabelNode,
                    lastFMPasswordInputNode
                ]
            )
            password?.style.alignSelf = .stretch
        }
        
        let vert = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .center,
            alignItems: .stretch,
            children: ArrayNoNils(
                lastFMLogoNode,
                LastFMScrobbler.shared.isLoggedIn ? loginInfoNode : nil,
                username,
                password,
                loginButtonNode
            )
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

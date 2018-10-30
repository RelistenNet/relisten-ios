//
//  SettingsViewController.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import LicensesViewController
import SVProgressHUD
import SafariServices

public class SettingsViewController : RelistenBaseTableViewController {
    enum Sections: Int, RawRepresentable {
        case lastFM = 0
        case downloads
        case bugReporting
        case credits
        case count
    }
    
    public init() {
        super.init()
        
        self.tableNode.view.separatorStyle = .singleLine
        self.tableNode.view.backgroundColor = AppColors.lightGreyBackground
        
        title = "Settings"
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var lastFMLoginNode : LastFMAccountNode = {
        return LastFMAccountNode(viewController: self)
    }()
    
    lazy var manageOfflineMusicNode : ManageOfflineMusicNode = {
        return ManageOfflineMusicNode(viewController: self)
    }()
    
    let bugReportingNode : BugReportingSettingsNode = BugReportingSettingsNode()
    
    lazy var creditsNode : CreditsNode = {
        return CreditsNode(viewController: self)
    }()
    
    lazy var licensesNode : ASTextCellNode = {
        let licensesNode = ASTextCellNode(attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .body)], insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        licensesNode.text = "Acknowledgements"
        licensesNode.accessoryType = .disclosureIndicator
        return licensesNode
    }()
    
    lazy var websiteNode : ASTextCellNode = {
        let websiteNode = ASTextCellNode(attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .body)], insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        websiteNode.text = "Desktop listening with relisten.net"
        websiteNode.accessoryType = .disclosureIndicator
        return websiteNode
    }()
    
    lazy var discordNode : ASTextCellNode = {
        let discordNode = ASTextCellNode(attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .body)], insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        discordNode.text = "Discuss Relisten on Discord"
        discordNode.accessoryType = .disclosureIndicator
        return discordNode
    }()
    
    lazy var githubNode : ASTextCellNode = {
        let githubNode = ASTextCellNode(attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .body)], insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        githubNode.text = "View project on Github"
        githubNode.accessoryType = .disclosureIndicator
        return githubNode
    }()
    
    lazy var sonosNode : ASTextCellNode = {
        let licensesNode = ASTextCellNode(attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .body)], insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        licensesNode.text = "Use Relisten on Sonos"
        licensesNode.accessoryType = .disclosureIndicator
        return licensesNode
    }()

    let licensesController = LicensesViewController()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        LastFMScrobbler.shared.observeUsername.observe { (username, _) in
            DispatchQueue.main.async {
                self.tableNode.reloadSections(IndexSet(integer: Sections.lastFM.rawValue), with: .none)
            }
        }.add(to: &disposal)
        
        LastFMScrobbler.shared.observeLoggedIn.observe { (current, previous) in
            if (current == previous) { return }
            
            DispatchQueue.main.async {
                self.tableNode.reloadSections(IndexSet(integer: Sections.lastFM.rawValue), with: .none)
            }
        }.add(to: &disposal)
    }
    
    // MARK: ASTableDataSource
    override public func numberOfSections(in tableNode: ASTableNode) -> Int {
        return Sections.count.rawValue
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section)! {
        case .lastFM:
            return 2
        case .downloads:
            return 1
        case .bugReporting:
            return 1
        case .credits:
            return 6
        case .count:
            fatalError()
        }
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        var n: ASCellNode
        
        switch Sections(rawValue: indexPath.section)! {
        case .lastFM:
            switch indexPath.row {
            case 0:
                let cell = ASTextCellNode(
                    attributes: [
                        NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .body),
                        NSAttributedString.Key.foregroundColor : UIColor.darkGray
                    ],
                    insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
                )
                
                cell.accessoryType = .none
                
                if LastFMScrobbler.shared.isLoggedIn {
                    cell.text = "You are signed in as @\(LastFMScrobbler.shared.username!)"
                }
                else {
                    cell.text = "You haven't connected your account"
                }
                
                n = cell
            case 1:
                let cell = ASTextCellNode(
                    attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .body)],
                    insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
                )
                
                cell.accessoryType = .disclosureIndicator
                
                if LastFMScrobbler.shared.isLoggedIn {
                    cell.text = "Sign Out"
                }
                else {
                    cell.text = "Sign In"
                }
                
                n = cell
            default:
                fatalError()
            }
        case .downloads:
            n = manageOfflineMusicNode
        case .bugReporting:
            n = bugReportingNode
        case .credits:
            switch indexPath.row {
            case 0:
                n = creditsNode
            case 1:
                n = licensesNode
            case 2:
                n = websiteNode
            case 3:
                n = discordNode
            case 4:
                n = githubNode
            case 5:
                n = sonosNode
            default:
                fatalError()
            }
            
        case .count:
            fatalError()
        }
        
        return n
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Sections(rawValue: section)! {
        case .lastFM:
            return "last.fm"
        case .downloads:
            return "Offline Music"
        case .bugReporting:
            return "Bug Reporting"
        case .credits:
            return "Credits"
        case .count:
            fatalError()
        }
    }
    
    override public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch Sections(rawValue: indexPath.section)! {
        case .lastFM:
            switch indexPath.row {
            case 1:
                return true
            default:
                return false
            }
        case .credits:
            switch indexPath.row {
            case 0:
                return false
            default:
                return true
            }
        default:
            return false
        }
    }
    
    override public func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        switch Sections(rawValue: indexPath.section)! {
        case .credits:
            switch indexPath.row {
            case 1:
                licensesController.loadPlist(Bundle.main, resourceName: "Credits")
                self.navigationController?.pushViewController(licensesController, animated: true)
            case 2:
                let url = URL(string: "https://relisten.net")!
                navigationController?.present(SFSafariViewController(url: url), animated: true, completion: nil)
            case 3:
                let url = URL(string: "https://discord.gg/u8v4The")!
                navigationController?.present(SFSafariViewController(url: url), animated: true, completion: nil)
            case 4:
                let url = URL(string: "https://github.com/relistennet/relisten-ios")!
                navigationController?.present(SFSafariViewController(url: url), animated: true, completion: nil)
            case 5:
                let url = URL(string: "https://twitter.com/relistenapp/status/1017138507956084736")!
                navigationController?.present(SFSafariViewController(url: url), animated: true, completion: nil)
            case 0:
                fallthrough
            default:
                fatalError()
            }
        case .lastFM:
            switch indexPath.row {
            case 1:
                if LastFMScrobbler.shared.isLoggedIn {
                    lastFMSignOut()
                }
                else {
                    lastFMSignIn()
                }
            default:
                fatalError()
            }
        default:
            fatalError()
        }
        tableNode.deselectRow(at: indexPath, animated: true)
    }
    
    public func lastFMSignIn() {
        let a = UIAlertController(
            title: "Sign into Last.FM",
            message: nil,
            preferredStyle: .alert
        )
        
        a.addTextField { (textField) in
            textField.placeholder = "Username"
            textField.autocorrectionType = .no
        }
        
        a.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        a.addAction(UIAlertAction(title: "Sign In", style: .default, handler: { (action) in
            SVProgressHUD.show()
            
            LastFMScrobbler.shared.login(
                username: a.textFields![0].text!,
                password: a.textFields![1].text!,
                completion: { (err) in
                    SVProgressHUD.dismiss()

                    guard let e = err else {
                        return
                    }
                    
                    let err = UIAlertController(
                        title: "Last.FM Error",
                        message: e.localizedDescription,
                        preferredStyle: .alert
                    )
                    
                    err.addAction(UIAlertAction(
                        title: "Okay",
                        style: .default,
                        handler: nil
                    ))
                    
                    self.present(err, animated: true, completion: nil)
                }
            )
        }))
        
        present(a, animated: true, completion: nil)
    }
    
    public func lastFMSignOut() {
        let err = UIAlertController(
            title: "Sign out of Last.FM?",
            message: "You are currently signed in as @\(LastFMScrobbler.shared.username!)",
            preferredStyle: .alert
        )
        
        err.addAction(UIAlertAction(
            title: "Cancel",
            style: .default,
            handler: nil
        ))
        
        err.addAction(UIAlertAction(
            title: "Sign Out",
            style: .destructive,
            handler: { (action) in
                LastFMScrobbler.shared.logout()
            }
        ))
        
        present(err, animated: true, completion: nil)
    }
}

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
import SafariServices

public class SettingsViewController : RelistenBaseAsyncTableViewController {
    enum Sections: Int, RawRepresentable {
        case downloads = 0
        case bugReporting
        case credits
        case count
    }
    
    public init() {
        super.init()
        
        self.tableNode.view.separatorStyle = .none
        self.tableNode.view.backgroundColor = AppColors.lightGreyBackground
        
        title = "Settings"
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var manageOfflineMusicNode : ManageOfflineMusicNode = {
        return ManageOfflineMusicNode(viewController: self)
    }()
    
    let bugReportingNode : BugReportingSettingsNode = BugReportingSettingsNode()
    
    lazy var creditsNode : CreditsNode = {
        return CreditsNode(viewController: self)
    }()
    
    lazy var licensesNode : ASTextCellNode = {
        let licensesNode = ASTextCellNode(attributes: [NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .body)], insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        licensesNode.text = "Acknowledgements"
        licensesNode.accessoryType = .disclosureIndicator
        return licensesNode
    }()
    
    lazy var websiteNode : ASTextCellNode = {
        let licensesNode = ASTextCellNode(attributes: [NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .body)], insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        licensesNode.text = "Desktop listening with relisten.net"
        licensesNode.accessoryType = .disclosureIndicator
        return licensesNode
    }()
    
    lazy var githubNode : ASTextCellNode = {
        let licensesNode = ASTextCellNode(attributes: [NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .body)], insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        licensesNode.text = "View project on Github"
        licensesNode.accessoryType = .disclosureIndicator
        return licensesNode
    }()
    
    lazy var sonosNode : ASTextCellNode = {
        let licensesNode = ASTextCellNode(attributes: [NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .body)], insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        licensesNode.text = "Use Relisten on Sonos"
        licensesNode.accessoryType = .disclosureIndicator
        return licensesNode
    }()

    let licensesController = LicensesViewController()
}

// MARK: ASTableDataSource
extension SettingsViewController {
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return Sections.count.rawValue
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section)! {
        case .downloads:
            return 1
        case .bugReporting:
            return 1
        case .credits:
            return 5
        case .count:
            fatalError()
        }
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        var n: ASCellNode
        
        switch Sections(rawValue: indexPath.section)! {
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
                n = githubNode
            case 4:
                n = sonosNode
            default:
                fatalError()
            }
            
        case .count:
            fatalError()
        }
        
        return n
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Sections(rawValue: section)! {
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
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch Sections(rawValue: indexPath.section)! {
        case .credits:
            switch indexPath.row {
            case 1:
                fallthrough
            case 2:
                fallthrough
            case 3:
                return true
            case 0:
                fallthrough
            default:
                return false
            }
        default:
            return false
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
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
                let url = URL(string: "https://github.com/relistennet/relisten-ios")!
                navigationController?.present(SFSafariViewController(url: url), animated: true, completion: nil)
            case 4:
                let url = URL(string: "https://twitter.com/relistenapp/status/1017138507956084736")!
                navigationController?.present(SFSafariViewController(url: url), animated: true, completion: nil)
            case 0:
                fallthrough
            default:
                fatalError()
            }
        default:
            fatalError()
        }
        tableNode.deselectRow(at: indexPath, animated: true)
    }
}

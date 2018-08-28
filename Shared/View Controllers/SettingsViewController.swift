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
        let licensesNode = ASTextCellNode(attributes: [NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .body)], insets: UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 10))
        licensesNode.text = "Acknowledgements"
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
            return 2
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

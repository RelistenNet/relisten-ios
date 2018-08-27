//
//  SettingsViewController.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/26/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import AsyncDisplayKit

public class SettingsViewController : RelistenBaseAsyncTableViewController {
    enum Sections: Int, RawRepresentable {
        case downloads = 0
        case bugReporting
        case credits
        case count
    }
    
    public init() {
        manageOfflineMusicNode = ManageOfflineMusicNode()
        bugReportingNode = BugReportingSettingsNode()
        creditsNode = CreditsNode()
        
        super.init()
        
        self.tableNode.view.separatorStyle = .none
        self.tableNode.view.backgroundColor = AppColors.lightGreyBackground
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let manageOfflineMusicNode : ManageOfflineMusicNode
    let bugReportingNode : BugReportingSettingsNode
    let creditsNode : CreditsNode
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
            return 1
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
            n = creditsNode
            
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
        return false
    }
}

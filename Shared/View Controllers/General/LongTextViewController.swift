//
//  LongTextViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import AsyncDisplayKit
import SafariServices

public class LongTextViewController : RelistenBaseAsyncTableViewController {
    public required init(attributedText: NSAttributedString) {
        textNode = ASTextCellNode()
        textNode.textNode.attributedText = attributedText
        textNode.textNode.isUserInteractionEnabled = true
        
        super.init(style: .plain)
        
        textNode.textNode.delegate = self
    }
    
    public required init(text: String, withFont font: UIFont) {
        textNode = ASTextCellNode(text, font: font)
        super.init(style: .plain)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableNode.view.separatorStyle = .none
        self.tableNode.view.backgroundColor = UIColor.white
        self.tableNode.view.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    let textNode: ASTextCellNode
    
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return 1
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        return textNode
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension LongTextViewController : ASTextNodeDelegate {
    public func textNode(_ textNode: ASTextNode!, shouldHighlightLinkAttribute attribute: String!, value: Any!, at point: CGPoint) -> Bool {
        return true
    }
    
    public func textNode(_ textNode: ASTextNode!, tappedLinkAttribute attribute: String!, value: Any!, at point: CGPoint, textRange: NSRange) {
        if let url = value as! URL? {
            navigationController?.present(SFSafariViewController(url: url), animated: true, completion: nil)
        }
    }
}

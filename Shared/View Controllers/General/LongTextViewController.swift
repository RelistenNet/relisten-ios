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

public class LongTextViewController : RelistenBaseTableViewController, UIViewControllerRestoration {
    public required init(attributedText: NSAttributedString) {
        textNode = ASTextCellNode()
        textNode.textNode.attributedText = attributedText
        textNode.textNode.isUserInteractionEnabled = true
        
        super.init(style: .plain)
        
        self.restorationIdentifier = "net.relisten.LongTextViewController"
        self.restorationClass = type(of: self)
        
        textNode.textNode.delegate = self
    }
    
    public convenience init(text: String, withFont font: UIFont) {
        let attributedText = RelistenAttributedString(text, font: font)
        self.init(attributedText: attributedText)
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
    
    override public func numberOfSections(in tableNode: ASTableNode) -> Int {
        return 1
    }
    
    override public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        return textNode
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    override public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    //MARK: State Restoration
    enum CodingKeys: String, CodingKey {
        case text = "text"
    }
    
    static public func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        if let encodedText = coder.decodeObject(forKey: CodingKeys.text.rawValue) as? NSAttributedString {
            let vc = LongTextViewController(attributedText: encodedText)
            return vc
        }
        return nil
    }
    
    override public func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(self.textNode.textNode.attributedText, forKey: CodingKeys.text.rawValue)
    }
    
    override public func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
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

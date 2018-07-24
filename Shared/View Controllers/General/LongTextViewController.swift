//
//  LongTextViewController.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

import LayoutKit
import SafariServices

public class LongTextViewController : RelistenBaseTableViewController {
    let attributedText: NSAttributedString?
    
    let text: String?
    let font: UIFont?
    
    public required init(attributedText: NSAttributedString) {
        self.attributedText = attributedText
        
        self.text = nil
        self.font = nil
        
        super.init(style: .plain)
    }
    
    public required init(text: String, withFont font: UIFont) {
        self.attributedText = nil
        
        self.text = text
        self.font = font
        
        super.init(style: .plain)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = UIColor.white
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        render()
    }
    
    func render() {
        layout {
            var textLayout: Layout! = nil
            
            if let attr = self.attributedText {
                textLayout = TextViewLayout(
                    attributedText: attr,
                    layoutAlignment: .fill,
                    flexibility: .inflexible,
                    viewReuseId: "attrText",
                    config: { textView in
                        textView.dataDetectorTypes = .link
                        textView.delegate = self
                    }
                )
            }
            
            if let text = self.text, let font = self.font {
                textLayout = LabelLayout(
                    text: text,
                    font: font,
                    alignment: .fill,
                    flexibility: .inflexible,
                    viewReuseId: "text",
                    config: nil
                )
            }
            
            return [
                LayoutsAsSingleSection(items: [InsetLayout(inset: 16, sublayout: textLayout)])
            ]
        }
    }
    
    public override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension LongTextViewController : UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction {
            navigationController?.present(SFSafariViewController(url: URL), animated: true, completion: nil)
            
            return false
        }
        
        return true
    }
}

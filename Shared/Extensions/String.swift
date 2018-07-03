//
//  String.swift
//  Relisten
//
//  Created by Alec Gorge on 5/31/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import UIKit

extension String {
    func convertHtml() -> NSAttributedString{
        let extended = appending("<style>body{font: -apple-system-body;}</style>")
        
        guard let data = extended.data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(
                data: data,
                options: [
                    NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html,
                    NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
        }
        catch{
            return NSAttributedString()
        }
    }
    
    /// Returns a string suitable for grouping by in a table view
    func groupNameForTableView() -> String {
        if self.count == 0 {
            return ""
        }
        var s = self[..<self.index(self.startIndex, offsetBy: 1)].uppercased()
        
        for ch in s.unicodeScalars {
            if CharacterSet.decimalDigits.contains(ch) {
                s = "#"
                break
            }
        }
        
        return s
    }
}


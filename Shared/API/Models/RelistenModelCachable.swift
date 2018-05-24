//
//  RelistenModelCachable.swift
//  Relisten
//
//  Created by Alec Gorge on 2/25/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import Cache

extension RelistenObject : Codable {
    enum CodingKeys: String, CodingKey
    {
        case originalJson
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toData(), forKey: .originalJson)
    }
}

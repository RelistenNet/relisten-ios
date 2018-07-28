//
//  RelistenModels.swift
//  Relisten
//
//  Created by Alec Gorge on 2/24/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import SwiftyJSON

public typealias SwJSON = JSON

public class RelistenObject {
    public let id: Int
    public let created_at: Date
    public let updated_at: Date
    
    public let originalJSON: JSON
    
    public required init(json: JSON) throws {
        id = try json["id"].int.required()
        created_at = try json["created_at"].dateTime.required()
        updated_at = try json["updated_at"].dateTime.required()
        
        originalJSON = json
    }
    
    public convenience required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let data = try values.decode(Data.self, forKey: .originalJson)
        
        try self.init(json: SwJSON(data: data))
    }
    
    
    public func toPrettyJSONString() -> String {
        return originalJSON.rawString(.utf8, options: .prettyPrinted)!
    }
    
    public func toData() throws -> Data {
        return try originalJSON.rawData()
    }
}

public protocol RelistenUUIDObject : Hashable {
    var uuid: String { get }
    
    var hashValue: Int { get }
}

public extension RelistenUUIDObject {
    var hashValue: Int {
        get {
            return uuid.hashValue
        }
    }
}

public func ==<T: RelistenUUIDObject>(lhs: T, rhs: T) -> Bool {
    return lhs.uuid == rhs.uuid
}

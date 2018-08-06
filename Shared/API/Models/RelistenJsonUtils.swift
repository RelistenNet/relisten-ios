//
//  RelistenJsonUtils.swift
//  Relisten
//
//  Created by Alec Gorge on 2/24/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import SwiftyJSON

extension Optional {
    func required(_ name: String = "<unknown>") throws -> Wrapped {
        guard let value = self else {
            throw MissingRequiredValue(name: name, type: Wrapped.self)
        }
        return value
    }
}

struct MissingRequiredValue: Error {
    let name: String?
    let type: Any.Type
}

class Formatter {
    
    private static var internalJsonDateFormatter: DateFormatter?
    private static var internalJsonDateTimeFormatter: DateFormatter?
    
    static var jsonDateFormatter: DateFormatter {
        if (internalJsonDateFormatter == nil) {
            internalJsonDateFormatter = DateFormatter()
            internalJsonDateFormatter!.dateFormat = "yyyy-MM-dd"
        }
        return internalJsonDateFormatter!
    }
    
    static var jsonDateTimeFormatter: DateFormatter {
        if (internalJsonDateTimeFormatter == nil) {
            internalJsonDateTimeFormatter = DateFormatter()
            internalJsonDateTimeFormatter!.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        }
        return internalJsonDateTimeFormatter!
    }
    
}

extension JSON {
    
    public var date: Date? {
        get {
            switch self.type {
            case .string:
                return Formatter.jsonDateFormatter.date(from: self.object as! String)
            default:
                return nil
            }
        }
    }
    
    public var uuid: UUID? {
        get {
            switch self.type {
            case .string:
                return UUID(uuidString: self.object as! String)
            default:
                return nil
            }
        }
    }
    
    public var toURL: URL? {
        get {
            switch self.type {
            case .string:
                return URL(string: self.object as! String)
            default:
                return nil
            }
        }
    }
    
    public var dateTime: Date? {
        get {
            switch self.type {
            case .string:
                return Formatter.jsonDateTimeFormatter.date(from: self.object as! String)
            default:
                return nil
            }
        }
    }
    
}

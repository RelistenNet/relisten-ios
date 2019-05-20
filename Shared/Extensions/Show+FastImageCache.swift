//
//  Show+FastImageCache.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 7/29/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import FastImageCache

public class ShowFICWrapper : NSObject, FICEntity {
    private let show : ShowCellDataSource
    
    public init(_ show: ShowCellDataSource) {
        self.show = show
    }
    
    public var fic_UUID: String { return show.uuid.uuidString }
    public var fic_sourceImageUUID: String { return show.uuid.uuidString }
    public func fic_sourceImageURL(withFormatName formatName: String) -> URL? {
        guard var components : URLComponents = URLComponents(string: "relisten://shatter") else {
            return nil
        }
        let queryDictionary : [String : String] = ["date" : show.display_date,
                                                   "venue" : show.venueDataSource?.name ?? "",
                                                   "location" : show.venueDataSource?.location ?? "",
                                                   "artistID" : String(show.artist_id)]
        var queryItems : [URLQueryItem] = []
        for (key, value) in queryDictionary {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = queryItems
        return components.url
        
    }
    
    public func fic_drawingBlock(for image: UIImage, withFormatName formatName: String) -> FICEntityImageDrawingBlock? {
        return { (context : CGContext, size: CGSize) in
            var bounds = CGRect.zero
            bounds.size = size
            context.clear(bounds)
            context.interpolationQuality = .high
            UIGraphicsPushContext(context)
            image.draw(in: bounds)
            UIGraphicsPopContext()
        }
    }
    
    public func placeholderColor() -> UIColor? {
        return AlbumArtImageCache.shared.baseColor(forEntity: self)
    }
}

extension ShowCellDataSource {
    public func fastImageCacheWrapper() -> ShowFICWrapper {
        return ShowFICWrapper(self)
    }
}

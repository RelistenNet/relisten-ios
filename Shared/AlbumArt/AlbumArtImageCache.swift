//
//  AlbumArtImageCache.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 7/29/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import ChameleonFramework
import FastImageCache

public enum AlbumArtImageFormat : String {
    case small = "net.relisten.ios.albumart.small"
    case medium = "net.relisten.ios.albumart.medium"
    case full = "net.relisten.ios.albumart.full"
}

class AlbumArtImageCache : NSObject, FICImageCacheDelegate {
    static let shared : AlbumArtImageCache = AlbumArtImageCache()
    public let cache : FICImageCache = FICImageCache.shared()
    
    public static let imageFormatSmall = "net.relisten.ios.albumart.small"
    public static let imageFormatMedium = "net.relisten.ios.albumart.medium"
    public static let imageFormatFull = "net.relisten.ios.albumart.full"
    
    public static let imageFormatSmallBounds = CGSize(width: 112 * 2, height: 112 * 2)
    public static let imageFormatMediumBounds = CGSize(width: 512, height: 512)
    public static let imageFormatFullBounds = CGSize(width: 768, height: 768)
    
    private let imageFamily = "net.relisten.ios.albumart"

    public override init() {
        let small = FICImageFormat()
        small.name = AlbumArtImageCache.imageFormatSmall
        small.family = imageFamily
        small.style = .style32BitBGR
        small.imageSize = AlbumArtImageCache.imageFormatSmallBounds
        small.maximumCount = 250
        small.devices = [.phone, .pad]
        small.protectionMode = .none
        
        let medium = FICImageFormat()
        medium.name = AlbumArtImageCache.imageFormatMedium
        medium.family = imageFamily
        medium.style = .style32BitBGR
        medium.imageSize = AlbumArtImageCache.imageFormatMediumBounds
        medium.maximumCount = 250
        medium.devices = [.phone, .pad]
        medium.protectionMode = .none
        
        let full = FICImageFormat()
        full.name = AlbumArtImageCache.imageFormatFull
        full.family = imageFamily
        full.style = .style32BitBGR
        full.imageSize = AlbumArtImageCache.imageFormatFullBounds
        full.maximumCount = 3
        full.devices = [.phone, .pad]
        full.protectionMode = .none
        
        cache.setFormats([small, medium, full])
        
        super.init()
        
        cache.delegate = self
    }
    
    private func components(from entity: FICEntity) -> URLComponents? {
        guard let requestURL = entity.fic_sourceImageURL(withFormatName: AlbumArtImageCache.imageFormatMedium) else { return nil }
        return URLComponents(url: requestURL, resolvingAgainstBaseURL: false)
    }
    
    private func parseShowInfo(from entity: FICEntity) -> (artistID : String?, date : String?, venue : String?, location : String?) {
        guard let components = components(from: entity) else { return (nil, nil, nil, nil) }
        
        let artistID : String? = components.queryValueForKey("artistID")
        let date : String? = components.queryValueForKey("date")
        let venue : String? = components.queryValueForKey("venue")
        let location : String? = components.queryValueForKey("location")
        
        return (artistID, date, venue, location)
    }
    
    // This returns 2000-1-1 if it can't parse the string
    private func parseDateComponents(from date: String) -> (year : Int, month : Int, day : Int) {
        guard date.count >= 10 else { return (2000, 1, 1) }
        let year = Int(date[..<(date.index(date.startIndex, offsetBy:4))]) ?? 2000
        let month = Int(date[date.index(date.startIndex, offsetBy:5)..<date.index(date.startIndex, offsetBy:7)]) ?? 1
        let day = Int(date[date.index(date.startIndex, offsetBy:8)..<date.index(date.startIndex, offsetBy:10)]) ?? 1
        
        return (year, month, day)
    }
    
    private func baseColor(year: Int, venue: String?, day: Int, artistID : String?) -> UIColor {
        return self.color(year: year, venue: venue, artistID: artistID)
    }
    
    public func baseColor(forEntity entity: FICEntity) -> UIColor? {
        let (artistID, d, venue, _) = parseShowInfo(from: entity)
        guard let date = d else { return nil }
        
        let (year, _, day) = parseDateComponents(from: date)
        
        return baseColor(year: year, venue: venue, day: day, artistID: artistID)
    }
    
    public func imageCache(_ imageCache: FICImageCache, wantsSourceImageFor entity: FICEntity, withFormatName formatName: String, completionBlock: FICImageRequestCompletionBlock? = nil) {
        DispatchQueue.global(qos: .default).async {
            var image : UIImage? = nil
            let (artistID, date, venue, location) = self.parseShowInfo(from: entity)
            if let date = date {
                let (year, month, day) = self.parseDateComponents(from: date)
                
                let baseColor = self.baseColor(year: year, venue: venue, day: day, artistID: artistID)
                
                UIGraphicsBeginImageContext(CGSize(width: 768, height: 768))
                
                switch ((year + month + day) % 4) {
                case 0:
                    RelistenAlbumArts.drawShatterExplosion(withBaseColor: baseColor, date: date, venue: venue, location: location, drawLabel: true)
                case 1:
                    RelistenAlbumArts.drawRandomFlowers(withBaseColor: baseColor, date: date, venue: venue, location: location, drawLabel: true)
                case 2:
                    RelistenAlbumArts.drawSplash(withBaseColor: baseColor, date: date, venue: venue, location: location, drawLabel: true)
                case 3:
                    fallthrough
                default:
                    RelistenAlbumArts.drawCityGlitters(withBaseColor: baseColor, date: date, venue: venue, location: location, drawLabel: true)
                }
                
                image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }
            
            DispatchQueue.main.async {
                completionBlock?(image)
            }
        }
    }
 
    static private let yearColors : [UIColor] = [
                                     UIColor.flatBlack(),
                                     UIColor.flatBlue(),
                                     UIColor.flatBrown(),
                                     UIColor.flatCoffee(),
                                     UIColor.flatForestGreen(),
                                     UIColor.flatGray(),
                                     UIColor.flatGreen(),
                                     UIColor.flatLime(),
                                     UIColor.flatMagenta(),
                                     UIColor.flatMaroon(),
                                     UIColor.flatMint(),
                                     UIColor.flatNavyBlue(),
                                     UIColor.flatOrange(),
                                     UIColor.flatPink(),
                                     UIColor.flatPlum(),
                                     UIColor.flatPowderBlue(),
                                     UIColor.flatPurple(),
                                     UIColor.flatRed(),
                                     UIColor.flatSand(),
                                     UIColor.flatSkyBlue(),
                                     UIColor.flatTeal(),
                                     UIColor.flatWatermelon(),
                                     UIColor.flatWhite(),
                                     UIColor.flatYellow(),
                                     UIColor.flatBlackDark(),
                                     UIColor.flatBlueDark(),
                                     UIColor.flatBrownDark(),
                                     UIColor.flatCoffeeDark(),
                                     UIColor.flatForestGreenDark(),
                                     UIColor.flatGrayDark(),
                                     UIColor.flatGreenDark(),
                                     UIColor.flatLimeDark(),
                                     UIColor.flatMagentaDark(),
                                     UIColor.flatMaroonDark(),
                                     UIColor.flatMintDark(),
                                     UIColor.flatNavyBlueDark(),
                                     UIColor.flatOrangeDark(),
                                     UIColor.flatPinkDark(),
                                     UIColor.flatPlumDark(),
                                     UIColor.flatPowderBlueDark(),
                                     UIColor.flatPurpleDark(),
                                     UIColor.flatRedDark(),
                                     UIColor.flatSandDark(),
                                     UIColor.flatSkyBlueDark(),
                                     UIColor.flatTealDark(),
                                     UIColor.flatWatermelonDark(),
                                     UIColor.flatWhiteDark(),
                                     UIColor.flatYellowDark()
    ]
    
    private func color(year: Int, venue : String?, artistID : String?) -> UIColor {
        return AlbumArtImageCache.yearColors[abs(year ^ (venue?.hash ?? 1) ^ (artistID?.hash ?? 0)) % AlbumArtImageCache.yearColors.count]
    }
}

extension URLComponents {
    public func queryValueForKey(_ key : String) -> String? {
        return self.queryItems?.filter({ $0.name == key }).first?.value
    }
}

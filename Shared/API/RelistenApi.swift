//
//  RelistenApi.swift
//  Relisten
//
//  Created by Alec Gorge on 2/24/17.
//  Copyright © 2017 Alec Gorge. All rights reserved.
//

import Foundation

import Siesta
import SwiftyJSON

/// Add to a reponse pipeline to wrap JSON responses with SwiftyJSON
let SwiftyJSONTransformer = ResponseContentTransformer(transformErrors: true) { JSON($0.content as AnyObject) }

/// Provides a .json convenience accessor to get raw JSON from resources
public extension TypedContentAccessors {
    var json: JSON {
        return typedContent(ifNone: JSON.null)
    }
}

public extension Resource {
    // desired functionality: always send a request but
    // get an immediate result from the cache
    @discardableResult
    func loadFromCacheThenUpdate() -> Request? {
        if isLoading {
            return loadIfNeeded()
        }
        else {
            return load()
        }
    }
}

// Depending on your taste, a Service can be a global var, a static var singleton, or a piece of more carefully
// controlled shared state passed between pieces of the app.

public let RelistenApi = _RelistenApi()

public class _RelistenApi {
    
    // MARK: Configuration
    
    private let service = Service(baseURL:"https://api.relisten.net" + "/api/v2")
    
    fileprivate init() {
        #if DEBUG
            // Bare-bones logging of which network calls Siesta makes:
            SiestaLog.Category.enabled = [] // [.network]
            
            // For more info about how Siesta decides whether to make a network call,
            // and when it broadcasts state updates to the app:
            //LogCategory.enabled = LogCategory.common
            
            // For the gory details of what Siesta’s up to:
            //LogCategory.enabled = LogCategory.detailed
        #endif
        
        // Global configuration
        
        service.configure {
            $0.expirationTime = 60 * 60 * 24 * 365 * 10 as TimeInterval
            
            $0.pipeline[.parsing].add(SwiftyJSONTransformer, contentTypes: ["*/json"])
            
            $0.pipeline[.parsing].cacheUsing(RelistenJsonCache())
            // $0.pipeline[.model].cacheUsing(RelistenRealmCache())
            
            $0.pipeline[.cleanup].add(RelistenCacher.shared)
            
            // Custom transformers can change any response into any other — in this case, replacing the default error
            // message with the one provided by the Github API.
            
            $0.pipeline[.cleanup].add(RelistenErrorMessageExtractor())
        }
        
        // Resource-specific configuration
        
        service.configureTransformer("/artists") {
            return try ($0.content as JSON).arrayValue.map(ArtistWithCounts.init)
        }
        
        service.configureTransformer("/artists/*") {
            return try SlimArtistWithFeatures(json: $0.content as JSON)
        }
        
        service.configureTransformer("/artists/*/years") {
            return try ($0.content as JSON).arrayValue.map(Year.init)
        }
        
        service.configureTransformer("/artists/*/years/*") {
            return try YearWithShows(json: $0.content)
        }
        
        service.configureTransformer("/artists/*/shows/*") {
            return try ShowWithSources(json: $0.content)
        }
        
        service.configureTransformer("/artists/*/shows/top") {
            return try ($0.content as JSON).arrayValue.map(Show.init)
        }
        
        service.configureTransformer("/artists/*/shows/on-date") {
            return try ($0.content as JSON).arrayValue.map(ShowWithArtist.init)
        }
        
        service.configureTransformer("/artists/shows/on-date") {
            return try ($0.content as JSON).arrayValue.map(ShowWithArtist.init)
        }
        
        service.configureTransformer("/artists/*/shows/today") {
            return try ($0.content as JSON).arrayValue.map(ShowWithArtist.init)
        }
        
        service.configureTransformer("/artists/*/shows/recently-updated") {
            return try ($0.content as JSON).arrayValue.map(ShowWithArtist.init)
        }
        
        service.configureTransformer("/artists/*/shows/recently-performed") {
            return try ($0.content as JSON).arrayValue.map(ShowWithArtist.init)
        }
        
        service.configureTransformer("/shows/*") {
            return try ($0.content as JSON).arrayValue.map(ShowWithArtist.init)
        }
        
        service.configureTransformer("/artists/*/shows/random") {
            return try ShowWithSources(json: $0.content)
        }
        
        service.configureTransformer("/artists/shows/on-date") {
            return try ($0.content as JSON).arrayValue.map(ShowWithArtist.init)
        }
        
        service.configureTransformer("/artists/*/shows/recently-added") {
            return try ($0.content as JSON).arrayValue.map(Show.init)
        }
        
        service.configureTransformer("/artists/*/venues") {
            return try ($0.content as JSON).arrayValue.map(VenueWithShowCount.init)
        }
        
        service.configureTransformer("/artists/*/venues/*") {
            return try VenueWithShows(json: $0.content)
        }
        
        service.configureTransformer("/artists/*/eras") {
            return try ($0.content as JSON).arrayValue.map(Era.init)
        }
        
        service.configureTransformer("/artists/*/songs") {
            return try ($0.content as JSON).arrayValue.map(SongWithShowCount.init)
        }
        
        service.configureTransformer("/artists/*/songs/*") {
            return try SongWithShows(json: $0.content)
        }

        service.configureTransformer("/artists/*/tours") {
            return try ($0.content as JSON).arrayValue.map(TourWithShowCount.init)
        }
        
        service.configureTransformer("/artists/*/tours/*") {
            return try TourWithShows(json: $0.content)
        }
        
        service.configureTransformer("/artists/*/sources/*/reviews") {
            return try ($0.content as JSON).arrayValue.map(SourceReview.init)
        }
        
        /*
        service.configure("/user/starred/* /*") {   // Github gives 202 for “starred” and 404 for “not starred.”
            $0.pipeline[.model].add(               // This custom transformer turns that curious convention into
                TrueIfResourceFoundTransformer())  // a resource whose content is a simple boolean.
        }
        */*/*/
 
        
        // Note that you can use Siesta without these sorts of model mappings. By default, Siesta parses JSON, text,
        // and images based on content type — and a resource will contain whatever the server happened to return, in a
        // parsed but unstructured form (string, dictionary, etc.). If you prefer to work with raw dictionaries instead
        // of models (good for rapid prototyping), then no additional transformer config is necessary.
        //
        // If you do apply a path-based mapping like the ones above, then any request for that path that does not return
        // the expected type becomes an error. For example, "/users/foo" _must_ return a JSON response because that's
        // what the User(json:) expects.
    }
    
    // MARK: Endpoints
    
    // You can turn your REST API into a nice Swift API using lightweight wrappers that return Siesta resources.
    //
    // Note that this class keeps its service private, making these methods the only entry points for the API.
    // You could also choose to subclass Service, which makes methods like service.resource(…) available to
    // your whole app. That approach is sometimes better for quick and dirty prototyping.
    
    public func artists() -> Resource {
        return service.resource("/artists")
    }
    
    public func artist(withSlug slug: String) -> Resource {
        return service
            .resource("/artists")
            .child(slug)
    }
    
    private func artistResource(_ forArtist: SlimArtist) -> Resource {
        return artist(withSlug: forArtist.slug)
    }
    
    public func years(byArtist: SlimArtist) -> Resource {
        return artistResource(byArtist).child("years")
    }
    
    public func shows(inYear: Year, byArtist: SlimArtist) -> Resource {
        return artistResource(byArtist)
            .child("years")
            .child(inYear.year)
    }
    
    public func showWithSources(forShow: Show, byArtist: SlimArtist) -> Resource {
        return artistResource(byArtist)
            .child("shows")
            .child(forShow.display_date)
    }
    
    public func venues(forArtist: SlimArtist) -> Resource {
        return artistResource(forArtist)
            .child("venues")
    }
    
    public func shows(atVenue: Venue, byArtist: SlimArtist) -> Resource {
        return artistResource(byArtist)
            .child("venues")
            .child(String(atVenue.id))
    }
    
    public func randomShow(byArtist: SlimArtist) -> Resource {
        return artistResource(byArtist)
            .child("shows")
            .child("random")
    }
    
    public func topShows(byArtist: SlimArtist) -> Resource {
        return artistResource(byArtist)
            .child("shows")
            .child("top")
    }
    
    public func recentlyAddedShows(byArtist: SlimArtist) -> Resource {
        return artistResource(byArtist)
            .child("shows")
            .child("recently-added")
            .withParam("previousDays", "60")
    }
    
    public func songs(byArtist: SlimArtist) -> Resource {
        return artistResource(byArtist)
            .child("songs")
    }
    
    public func shows(withPlayedSong: Song, byArtist: SlimArtist) -> Resource {
        return artistResource(byArtist)
            .child("songs")
            .child(String(withPlayedSong.id))
    }
    
    public func show(onDate: String /* YYYY-MM-DD */, byArtist: SlimArtist) -> Resource {
        return artistResource(byArtist)
            .child("shows")
            .child(onDate)
    }
    
    public func reviews(forSource: Source, byArtist: SlimArtist) -> Resource {
        return artistResource(byArtist)
            .child("sources")
            .child(String(forSource.id))
            .child("reviews")
    }
    
    public func onThisDay(byArtist: SlimArtist) -> Resource {
        let date = Date()
        let calendar = Calendar.current
        
        return artistResource(byArtist)
            .child("shows")
            .child("on-date")
            .withParam("month", String(calendar.component(.month, from: date)))
            .withParam("day", String(calendar.component(.day, from: date)))
    }
    
    public func recentlyUpdated(byArtist: SlimArtist) -> Resource {
        return artistResource(byArtist)
            .child("shows")
            .child("recently-updated")
    }
    
    public func recentlyPerformed(byArtist: SlimArtist) -> Resource {
        return artistResource(byArtist)
            .child("shows")
            .child("recently-performed")
    }
    
    public func recentlyPerformed(byArtists: [UUID]) -> Resource {
        return service
            .resource("shows")
            .child("recently-performed")
            .withParam("artistIds", json(from: byArtists.map { $0.uuidString }))
    }

    public func recentlyUpdated() -> Resource {
        return service
            .resource("shows")
            .child("recently-updated")
    }
    
    public func recentlyPerformed() -> Resource {
        return service
            .resource("shows")
            .child("recently-performed")
    }
    
    public func play(_ track: SourceTrack) -> Resource {
        return service
            .resource("live")
            .child("play")
            .withParam("app_type", "ios")
            .withParam("track_id", String(track.id))
    }
    
    public func recordPlay(_ track: SourceTrack) -> Request {
        return play(track).request(.post)
    }
}

func json(from object:Any) -> String? {
    guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
        return nil
    }
    return String(data: data, encoding: String.Encoding.utf8)
}

/// If the response is JSON and has a "message" value, use it as the user-visible error message.
private struct RelistenErrorMessageExtractor: ResponseTransformer {
    func process(_ response: Response) -> Response {
        switch response {
        case .success:
            return response
            
        case .failure(var error):
            // Note: the .json property here is defined in Siesta+SwiftyJSON.swift
            if let str: String = error.typedContent() {
                error.userMessage = str
            }
            
            return .failure(error)
        }
    }
}

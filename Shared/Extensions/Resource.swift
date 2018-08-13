//
//  Resource.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/12/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import Siesta

extension Resource {
    func getLatestDataOrFetchIfNeeded(completion: @escaping (Entity<Any>?, Error?) -> Void) {
        if let latestData = self.latestData {
            completion(latestData, nil)
            return
        }
        
        if let request = self.loadFromCacheThenUpdate() {
            request.onCompletion { (responseInfo) in
                var latestData : Entity<Any>? = nil
                var error : RequestError? = nil
                switch responseInfo.response {
                case .success(let responseData):
                    latestData = responseData
                case .failure(let responseError):
                    error = responseError
                    break
                }
                completion(latestData, error)
            }
        } else {
            completion(nil, RequestError(userMessage: "Couldn't load siesta request", cause: RequestError.Cause.RequestLoadFailed()))
        }
    }
}

extension RequestError.Cause {
    public struct RequestLoadFailed : Error { }
}

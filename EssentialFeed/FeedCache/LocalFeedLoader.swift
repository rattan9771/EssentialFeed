//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Rattan Das on 24/12/23.
//

import Foundation

public final class LocalFeedLoader {
    
    let store : FeedStore
    private let currentDate : () -> Date
    
    public typealias SaveResult = Error?
    
    public init(store : FeedStore, currentDate : @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ feed : [FeedImage] , completion : @escaping (SaveResult) -> Void) {
        
        store.deleteCachedFeed {[weak self] error in
            guard let self = self else {return}
            
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            }else {
                self.cache(feed: feed, completion: completion)
            }
    
        }
    }
    
    private func cache(feed : [FeedImage], completion : @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), timestamp: currentDate()) {  [weak self] error in
            guard self != nil else {return}
            completion(error)
        }
    }
}

extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map {LocalFeedImage(id: $0.id, url: $0.url, description: $0.description, location: $0.location)}
    }
}


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
    
    public func save(_ items : [FeedItem] , completion : @escaping (SaveResult) -> Void) {
        
        store.deleteCachedFeed {[weak self] error in
            guard let self = self else {return}
            
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            }else {
                self.cache(items: items, completion: completion)
            }
    
        }
    }
    
    private func cache(items : [FeedItem], completion : @escaping (SaveResult) -> Void) {
        store.insert(items.toLocal(), timestamp: currentDate()) {  [weak self] error in
            guard self != nil else {return}
            completion(error)
        }
    }
}

extension Array where Element == FeedItem {
    func toLocal() -> [LocalFeedItem] {
        return map {LocalFeedItem(id: $0.id, imageURL: $0.imageURL, description: $0.description, location: $0.location)}
    }
}


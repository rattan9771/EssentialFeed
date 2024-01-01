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
    private let calender = Calendar(identifier: .gregorian)
    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    
    public init(store : FeedStore, currentDate : @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func load(completion : @escaping (LoadResult) -> Void ) {
        store.retrieve {[weak self] result in
            guard let self = self else {return}
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .found(feed, timestamp) where self.validate(timestamp):
                completion(.success(feed.toModels()))
            case .found:
                completion(.success([]))
            case .empty:
                completion(.success([]))
            }
        }
    }
    
    public func validateCache() {
        store.retrieve {[unowned self] result in
            switch result {
            case .failure:
                self.store.deleteCachedFeed{ _ in }
            case let .found(feed: _, timeStamp) where !self.validate(timeStamp):
                self.store.deleteCachedFeed{ _ in }
            case .empty, .found:
                break
            }
            
        }
        
    }
    
    private func maxCacheAge() -> Int {
        return 7
    }
    
    private func validate(_ timestamp : Date) -> Bool {
       
        guard let maxCacheAge = calender.date(byAdding: .day, value: maxCacheAge(), to: timestamp) else {return false }
        return currentDate() < maxCacheAge
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

extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map {FeedImage(id: $0.id, url: $0.url, description: $0.description, location: $0.location)}
    }
}




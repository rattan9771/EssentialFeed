//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Rattan Das on 24/12/23.
//

import Foundation

public enum RetrieveCachedFeedResult {
    case empty
    case found(feed : [LocalFeedImage] , timeStamp : Date)
    case failure(Error)
}

public protocol FeedStore {
    
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrivalCompletion = (RetrieveCachedFeedResult) -> Void
    
    func deleteCachedFeed(completion : @escaping DeletionCompletion )
    func insert(_ feed : [LocalFeedImage], timestamp: Date, completion : @escaping InsertionCompletion )
    func retrieve(completion : @escaping RetrivalCompletion)
}



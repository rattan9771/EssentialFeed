//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Rattan Das on 24/12/23.
//

import Foundation


public protocol FeedStore {
    
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion : @escaping DeletionCompletion )
    func insert(_ items : [FeedItem], timestamp: Date, completion : @escaping InsertionCompletion )
}


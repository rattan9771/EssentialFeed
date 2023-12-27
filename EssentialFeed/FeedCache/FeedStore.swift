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
    func insert(_ items : [LocalFeedItem], timestamp: Date, completion : @escaping InsertionCompletion )
}


public struct LocalFeedItem : Equatable {
    
    public let id : UUID
    public let imageURL : URL
    public let description : String?
    public let location: String?
    
    public init(id: UUID, imageURL: URL, description: String?, location: String?) {
        self.id = id
        self.imageURL = imageURL
        self.description = description
        self.location = location
    }
    
}

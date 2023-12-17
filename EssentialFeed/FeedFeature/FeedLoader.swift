//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Rattan on 06/11/23.
//

import Foundation

public enum LoadFeedResult{
    case success([FeedItem])
    case failure(Error)
}

public protocol FeedLoader {
     func load(completion : @escaping(LoadFeedResult) -> Void )
}

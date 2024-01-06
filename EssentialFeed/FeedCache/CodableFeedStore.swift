//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Rattan Das on 07/01/24.
//

import Foundation


public class CodableFeedStore : FeedStore {
    
    private struct Cache : Codable {
        let feed : [CodableFeedImage]
        let timestamp : Date
        
        var localFeed : [LocalFeedImage] {
            return feed.map { $0.local}
        }
    }
    
    private struct CodableFeedImage : Codable {
        private let id : UUID
        private let url : URL
        private let description : String?
        private let location: String?
        
        init(_ image : LocalFeedImage) {
            self.id = image.id
            self.url = image.url
            self.description = image.description
            self.location = image.location
        }
        
        var local : LocalFeedImage {
            return LocalFeedImage(id: id, url: url, description: description, location: location)
        }
    }
    
    private let storeURL : URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func retrieve(completion : @escaping FeedStore.RetrivalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timeStamp: cache.timestamp))
        }catch {
            completion(.failure(error))
        }
     }
    
    public func insert(_ feed : [LocalFeedImage], timestamp: Date, completion : @escaping FeedStore.InsertionCompletion ) {
        
        do{
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(Cache(feed: feed.map(CodableFeedImage.init) , timestamp: timestamp))
            try encoded.write(to: storeURL)
            completion(nil)
        }catch {
            completion(error)
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return completion(nil)
        }
        
        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        }catch {
            completion(error)
        }
    }
}

//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Rattan Das on 06/01/24.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    
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
    
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "image-feed.store")
    
    func retrieve(completion : @escaping FeedStore.RetrivalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timeStamp: cache.timestamp))
        
    }
    
    func insert(_ feed : [LocalFeedImage], timestamp: Date, completion : @escaping FeedStore.InsertionCompletion ) {
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(Cache(feed: feed.map(CodableFeedImage.init) , timestamp: timestamp))
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

final class CodableFeedStoreTests: XCTestCase {

    override func setUpWithError() throws {
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    override func tearDownWithError() throws {
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    func test_retrieve_deliverEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "wait for cache retrival")
        
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "wait for cache retrival")
        
        sut.retrieve {firstResult in
            sut.retrieve { secondResult in
                switch (firstResult , secondResult) {
                case (.empty , .empty):
                    break
                default:
                    XCTFail("Expected receiving twice from empty cache to deliver same empty result, got \(firstResult) and second \(secondResult) instead")
                }
                
                exp.fulfill()
            }
        }
        
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieveAfterInsertionToEmptyCache_deliverInsertedValues() {
        let sut = CodableFeedStore()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let exp = expectation(description: "wait for cache retrival")
        
        sut.insert(feed, timestamp: timestamp) {insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            
            sut.retrieve { retrieveResult in
                switch retrieveResult {
                case let .found(feed: retrieveFeed, timeStamp: retrievedTimeStamp):
                   XCTAssertEqual(retrieveFeed, feed)
                    XCTAssertEqual(retrievedTimeStamp, timestamp)
                default:
                    XCTFail("Expected found result with feed \(feed) and timestamp \(timestamp) , got \(retrieveResult) instead")
                }
                
                exp.fulfill()
            }
        }
        
        
        wait(for: [exp], timeout: 1.0)
    }
    
}

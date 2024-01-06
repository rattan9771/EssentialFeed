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
    
    private let storeURL : URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
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
        setUpEmptyStoreState()
    }

    override func tearDownWithError() throws {
        undoStoreSideEffects()
    }

    func test_retrieve_deliverEmptyOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieveTwice: .empty)
        
    }
    
    func test_retrieveAfterInsertionToEmptyCache_deliverInsertedValues() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
       
        insert((feed, timestamp), to: sut)
       
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp))
       
    }
    
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieveTwice: .found(feed: feed, timeStamp: timestamp))
    }
    
    
    //MARK:- Helper
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackMemoryLeak(sut)
        return sut
    }
    
    private func insert(_ cache: (feed : [LocalFeedImage], timestamp : Date), to sut : CodableFeedStore ) {
        let exp = expectation(description: "wait for cache insertion")
        
        sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
            XCTAssertNil(insertionError , "Expected feed to be inserted successfully")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func expect(_ sut: CodableFeedStore , toRetrieveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    private func expect(_ sut: CodableFeedStore , toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        
        let exp = expectation(description: "wait for cache retreival")
        
        sut.retrieve { receivedResult in
            switch (expectedResult, receivedResult) {
            case (.empty , .empty):
                break
                
            case let (.found(feed: expectedFeed, timeStamp: expectedTimeStamp), .found(feed: receivedFeed, timeStamp: receivedTimeStamp)):
                XCTAssertEqual(expectedFeed, receivedFeed, file: file, line: line)
                XCTAssertEqual(expectedTimeStamp, receivedTimeStamp, file: file, line: line)
                
            default:
                XCTFail("Expected to retrieve \(expectedResult) , got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func setUpEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "\(type(of: self)).store")
    }
}

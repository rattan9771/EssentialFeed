//
//  ValidateFeedCacheUseTestCases.swift
//  EssentialFeedTests
//
//  Created by Rattan Das on 01/01/24.
//

import XCTest
import EssentialFeed

final class ValidateFeedCacheUseTestCases: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testExample() throws {}

    func testPerformanceExample() throws {
        self.measure {}
    }

    func test_init_doesNotMessageStoreUponCreation() {
        let (_ , store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_validateCache_deletesCacheOnRetrivalError() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        
        store.completeRetrival(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve , .deletedCachedFeed])
    }
    
    func test_validateCache_doesNotDeletesCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        
        store.completeRetrivalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve ])
    }

    func test_validateCache_doesNotDeletesNonExpiredCache(){
        let feed = uniqueImageFeed()
         let fixedCurrentDate = Date()
         let nonExpiredTimeStamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
         
         let (sut , store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrival(with: feed.local, timestamp: nonExpiredTimeStamp)
        XCTAssertEqual(store.receivedMessages, [.retrieve ])
    }
    
    func test_validateCache_deletesCacheOnExpiration(){
        let feed = uniqueImageFeed()
         let fixedCurrentDate = Date()
         let expirationTimeStamp = fixedCurrentDate.minusFeedCacheMaxAge()
         
         let (sut , store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrival(with: feed.local, timestamp: expirationTimeStamp)
        XCTAssertEqual(store.receivedMessages, [.retrieve , .deletedCachedFeed])
    }
    
    func test_validateCache_deletesExpiredCache(){
        let feed = uniqueImageFeed()
         let fixedCurrentDate = Date()
        let expiredTimeStamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
         
         let (sut , store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrival(with: feed.local, timestamp: expiredTimeStamp)
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deletedCachedFeed])
    }
    
    func test_validateCache_doesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut : LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        sut?.validateCache()
        
        sut = nil
        store.completeRetrival(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    //MARK:- Helper
    private func makeSUT(currentDate: (@escaping () -> Date) = Date.init , file: StaticString = #file,line: UInt = #line) -> (sut : LocalFeedLoader, store : FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate : currentDate)
        trackMemoryLeak(store, file: file, line: line)
        trackMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }
    
     
}

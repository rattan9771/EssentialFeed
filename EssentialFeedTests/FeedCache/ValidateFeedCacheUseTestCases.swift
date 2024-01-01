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

    func test_validateCache_doesNotDeletesLessThanSevenDaysOldCache(){
        let feed = uniqueImageFeed()
         let fixedCurrentDate = Date()
         let lessThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
         
         let (sut , store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrival(with: feed.local, timestamp: lessThanSevenDaysOldTimeStamp)
        XCTAssertEqual(store.receivedMessages, [.retrieve ])
    }
    
    private func makeSUT(currentDate: (@escaping () -> Date) = Date.init , file: StaticString = #file,line: UInt = #line) -> (sut : LocalFeedLoader, store : FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate : currentDate)
        trackMemoryLeak(store, file: file, line: line)
        trackMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    
    private func uniqueImageFeed() -> (models : [FeedImage] , local: [LocalFeedImage]) {
        let items = [uniqueImage() , uniqueImage()]
        let localItems = items.map({ LocalFeedImage(id: $0.id, url: $0.url, description: $0.description, location: $0.location)})
        return (items, localItems)
    }
    
    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), url: anyURL(), description: "any", location: "any")
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }
     
}
private extension Date {
    func adding(days : Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds : Int) -> Date {
        return self + TimeInterval(seconds)
    }
}

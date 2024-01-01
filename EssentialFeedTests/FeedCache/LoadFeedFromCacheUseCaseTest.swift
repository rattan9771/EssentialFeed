//
//  LoadFeedFromCacheUseCaseTest.swift
//  EssentialFeedTests
//
//  Created by Rattan Das on 28/12/23.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTest: XCTestCase {

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
    
    func test_load_requestsCachedRetrival() {
        let (sut , store) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrivalError() {
        let (sut , store) = makeSUT()
        let retrivalError = anyNSError()
        
        expect(sut, toCompleteWith: .failure(retrivalError)) {
            store.completeRetrival(with: retrivalError)
        }
        
    }
    

    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut , store) = makeSUT()
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrivalWithEmptyCache()
        }
        
    }
    
    func test_load_deliversCachedImagesOnLessThanSevenDaysOldCache() {
       let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        
        let (sut , store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success(feed.models)) {
            store.completeRetrival(with: feed.local, timestamp : lessThanSevenDaysOldTimeStamp)
        }
    }
    
    func test_load_deliversNoImagesOnSevenDaysOldCache() {
       let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7)
        
        let (sut , store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrival(with: feed.local, timestamp : sevenDaysOldTimeStamp)
        }
    }
    
    func test_load_deliversNoImagesOnMoreThanSevenDaysOldCache() {
       let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        
        let (sut , store) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrival(with: feed.local, timestamp : moreThanSevenDaysOldTimeStamp)
        }
    }

    func test_load_hasNoSideEffectsOnRetrivalError() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        store.completeRetrival(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve ])
    }
    
    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        store.completeRetrivalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve ])
    }

    func test_load_hasNoSideEffectsOnLessThanSevenDaysOldCache(){
        let feed = uniqueImageFeed()
         let fixedCurrentDate = Date()
         let lessThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
         
         let (sut , store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load{ _ in }
        store.completeRetrival(with: feed.local, timestamp: lessThanSevenDaysOldTimeStamp)
        XCTAssertEqual(store.receivedMessages, [.retrieve ])
    }
    
    func test_load_deletesCacheOnSevenDaysOldCache(){
        let feed = uniqueImageFeed()
         let fixedCurrentDate = Date()
         let sevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7)
         
         let (sut , store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load{ _ in }
        store.completeRetrival(with: feed.local, timestamp: sevenDaysOldTimeStamp)
        XCTAssertEqual(store.receivedMessages, [.retrieve , .deletedCachedFeed])
    }
    
    func test_load_deletesCacheOnMoreThanSevenDaysOldCache(){
        let feed = uniqueImageFeed()
         let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
         
         let (sut , store) = makeSUT(currentDate: { fixedCurrentDate })
        
        sut.load{ _ in }
        store.completeRetrival(with: feed.local, timestamp: moreThanSevenDaysOldTimeStamp)
        XCTAssertEqual(store.receivedMessages, [.retrieve , .deletedCachedFeed])
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut : LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResult = [LocalFeedLoader.LoadResult]()
        sut?.load{receivedResult.append($0)}
        
        sut = nil
        store.completeRetrivalWithEmptyCache()
        
        XCTAssertTrue(receivedResult.isEmpty)
    }
    
    //MARK:- HELPER
    
    private func makeSUT(currentDate: (@escaping () -> Date) = Date.init , file: StaticString = #file,line: UInt = #line) -> (sut : LocalFeedLoader, store : FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate : currentDate)
        trackMemoryLeak(store, file: file, line: line)
        trackMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut : LocalFeedLoader, toCompleteWith expectedResult : LocalFeedLoader.LoadResult, when action: () -> Void , file: StaticString = #file,line: UInt = #line) {
        
        let exp = expectation(description: "wait for load completion")
        
       
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedImages) , .success(expectedImages) ):
                XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
                
            case let ( .failure(receivedError) , .failure(expectedError) ):
                XCTAssertEqual(receivedError.localizedDescription , expectedError.localizedDescription, file: file, line: line)
                
            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead",file: file, line: line)
            }
            exp.fulfill()
        }
       
        action()
        wait(for: [exp], timeout: 1.0)
       
    }
    
   
    

}

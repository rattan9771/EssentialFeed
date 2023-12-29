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
        let exp = expectation(description: "wait for load completion")
        
        var receivedError: Error?
        sut.load { error in
            receivedError = error
            exp.fulfill()
        }
        
        store.completeRetrival(with: retrivalError)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as? NSError, retrivalError)
    }
    
    //MARK:- HELPER
    
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
    

}

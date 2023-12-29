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
    
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    

}

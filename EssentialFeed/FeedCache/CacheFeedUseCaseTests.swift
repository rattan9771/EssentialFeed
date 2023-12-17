//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Rattan Das on 17/12/23.
//

import XCTest

class FeedStore {
    var deleteCachedFeedCallCount  = 0
}

class LocalFeedStore {
    init(store : FeedStore) {
        
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testExample() throws {}

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func test_init_doesNotDeleteCacheUponCreation() {
        
        let store = FeedStore()
        _ = LocalFeedStore(store: store)
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }

}

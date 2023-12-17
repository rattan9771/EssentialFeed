//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Rattan Das on 17/12/23.
//

import XCTest
import EssentialFeed


class LocalFeedLoader {
    
    let store : FeedStore
    
    init(store : FeedStore) {
        self.store = store
    }
    
    func save(_ items : [FeedItem] ) {
        store.deleteCachedFeed()
    }
}

class FeedStore {
    var deleteCachedFeedCallCount  = 0
    
    func deleteCachedFeed() {
        deleteCachedFeedCallCount += 1
    }
}



final class CacheFeedUseCaseTests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testExample() throws {}

   
    
    func test_init_doesNotDeleteCacheUponCreation() {
        
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_requestCacheDeletion() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        let items = [uniqueItem() , uniqueItem()]
        sut.save(items)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }

    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), imageURL: anyURL(), description: "any", location: "any")
    }
    
    private func anyURL() -> URL {
        
        return URL(string: "https://any-url.com")!
    }
     
}

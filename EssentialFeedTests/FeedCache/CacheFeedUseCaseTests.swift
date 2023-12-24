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
    private let currentDate : () -> Date
    
    init(store : FeedStore, currentDate : @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items : [FeedItem] ) {
        store.deleteCachedFeed {[unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: self.currentDate())
            }
        }
    }
}

class FeedStore {
    
    typealias DeletionCompletion = (Error?) -> Void
    
    var deleteCachedFeedCallCount  = 0
    var insertCallCount = 0
    var insertion = [(items : [FeedItem] , timestamp : Date)]()
    
    private var deletionCompletion =  [DeletionCompletion]()
    
    func deleteCachedFeed(completion : @escaping DeletionCompletion ) {
        deleteCachedFeedCallCount += 1
        deletionCompletion.append(completion)
    }
    
    func completeDeletion(with error : Error, at index : Int = 0 ) {
        deletionCompletion[index](error)
    }
    
    func completeDeletionSuccessfully(at index : Int = 0 ) {
        deletionCompletion[index](nil)
    }
    
    func insert(_ items : [FeedItem], timestamp: Date ) {
        insertCallCount += 1
        insertion.append((items, timestamp))
    }
}



final class CacheFeedUseCaseTests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testExample() throws {}

   
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_ , store) = makeSUT()
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_requestCacheDeletion() {
        
        
        let items = [uniqueItem() , uniqueItem()]
        let (sut , store) = makeSUT()
        sut.save(items)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let items = [uniqueItem() , uniqueItem()]
        let (sut , store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(items)
        store.completeDeletion(with : deletionError)

        
        XCTAssertEqual(store.insertCallCount, 0)
    }
    
    func test_save_requestNewCacheInsetionOnSuccessfulDeletion() {
        let items = [uniqueItem() , uniqueItem()]
        let (sut , store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(items)
        store.completeDeletionSuccessfully()

        
        XCTAssertEqual(store.insertCallCount, 1)
    }
    
    func test_save_requestNewCacheInsetionWithTimeStampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = [uniqueItem() , uniqueItem()]
        let (sut , store) = makeSUT(currentDate: { timestamp })
        let deletionError = anyNSError()
        
        sut.save(items)
        store.completeDeletionSuccessfully()

        
        XCTAssertEqual(store.insertCallCount, 1)
        XCTAssertEqual(store.insertion.first?.items, items)
        XCTAssertEqual(store.insertion.first?.timestamp, timestamp)
    }
    
   
    private func makeSUT(currentDate: (@escaping () -> Date) = Date.init , file: StaticString = #file,
                         line: UInt = #line) -> (sut : LocalFeedLoader, store : FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate : currentDate)
        trackMemoryLeak(store, file: file, line: line)
        trackMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), imageURL: anyURL(), description: "any", location: "any")
    }
    
    private func anyURL() -> URL {
        
        return URL(string: "https://any-url.com")!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    
     
}

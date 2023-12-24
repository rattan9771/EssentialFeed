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
  
    
    private var deletionCompletion =  [DeletionCompletion]()
    
    enum ReceivedMessage : Equatable {
        case deletedCachedFeed
        case insert([FeedItem] , Date)
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    func deleteCachedFeed(completion : @escaping DeletionCompletion ) {
        deletionCompletion.append(completion)
        
        receivedMessages.append(.deletedCachedFeed)
    }
    
    func completeDeletion(with error : Error, at index : Int = 0 ) {
        deletionCompletion[index](error)
    }
    
    func completeDeletionSuccessfully(at index : Int = 0 ) {
        deletionCompletion[index](nil)
    }
    
    func insert(_ items : [FeedItem], timestamp: Date ) {
        receivedMessages.append(.insert(items, timestamp))
    }
}



final class CacheFeedUseCaseTests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testExample() throws {}

   
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_ , store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestCacheDeletion() {
        
        
        let items = [uniqueItem() , uniqueItem()]
        let (sut , store) = makeSUT()
        sut.save(items)
        
        XCTAssertEqual(store.receivedMessages, [.deletedCachedFeed])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let items = [uniqueItem() , uniqueItem()]
        let (sut , store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(items)
        store.completeDeletion(with : deletionError)

        
        XCTAssertEqual(store.receivedMessages, [.deletedCachedFeed])
    }
    
   
    
    func test_save_requestNewCacheInsetionWithTimeStampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = [uniqueItem() , uniqueItem()]
        let (sut , store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items)
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages, [.deletedCachedFeed, .insert(items, timestamp)])
        
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

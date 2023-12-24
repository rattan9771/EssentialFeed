//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Rattan Das on 17/12/23.
//

import XCTest
import EssentialFeed





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
        sut.save(items){ _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deletedCachedFeed])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let items = [uniqueItem() , uniqueItem()]
        let (sut , store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(items){ _ in }
        store.completeDeletion(with : deletionError)

        
        XCTAssertEqual(store.receivedMessages, [.deletedCachedFeed])
    }
    
   
    
    func test_save_requestNewCacheInsetionWithTimeStampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = [uniqueItem() , uniqueItem()]
        let (sut , store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items){ _ in }
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages, [.deletedCachedFeed, .insert(items, timestamp)])
        
    }
    
    func test_save_failsOnDeletionError() {
      
        let (sut , store) = makeSUT()
        let deletionError = anyNSError()
        
        
        expect(sut, toCompleteWithError: deletionError) {
            store.completeDeletion(with : deletionError)
        }
        
    }
    
    func test_save_failsOnInsertionError() {

        let (sut , store) = makeSUT()
        let insertionError = anyNSError()
        
        
        expect(sut, toCompleteWithError: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with : insertionError)
        }
        
    }
    
    func test_save_succeedOnSuccessfulCacheInsertion() {
        let (sut , store) = makeSUT()
        
        expect(sut, toCompleteWithError: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
    
    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut : LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [Error?]()
        sut?.save([uniqueItem()], completion: {receivedResults.append($0)})
        
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        
        let store = FeedStoreSpy()
        var sut : LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [Error?]()
        sut?.save([uniqueItem()], completion: {receivedResults.append($0)})
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
   
    private func makeSUT(currentDate: (@escaping () -> Date) = Date.init , file: StaticString = #file,line: UInt = #line) -> (sut : LocalFeedLoader, store : FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate : currentDate)
        trackMemoryLeak(store, file: file, line: line)
        trackMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut : LocalFeedLoader, toCompleteWithError expectedError: NSError? , when action : () -> Void ,  file: StaticString = #file,line: UInt = #line) {
        let exp = expectation(description: "wait for save completion")
        
        var receivedError :  Error?
        sut.save([uniqueItem()]) { error in
            receivedError = error
            exp.fulfill()
        }
        
        
        action()
        wait(for: [exp] , timeout: 1.0)
        
        XCTAssertEqual(receivedError as? NSError, expectedError, file: file, line: line)
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
    
    private class FeedStoreSpy : FeedStore {
        
        typealias DeletionCompletion = (Error?) -> Void
        typealias InsertionCompletion = (Error?) -> Void
        
        private var deletionCompletion =  [DeletionCompletion]()
        private var insertionCompletion = [InsertionCompletion]()
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
        
        func insert(_ items : [FeedItem], timestamp: Date, completion : @escaping InsertionCompletion ) {
            insertionCompletion.append(completion)
            receivedMessages.append(.insert(items, timestamp))
        }
        
        func completeInsertion(with error : Error, at index : Int = 0 ) {
            insertionCompletion[index](error)
        }
        
        func completeInsertionSuccessfully( at index : Int = 0 ) {
            insertionCompletion[index](nil)
        }
    }
    
     
}

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
        
        let (sut , store) = makeSUT()
        sut.save(uniqueImageFeed().models){ _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deletedCachedFeed])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut , store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(uniqueImageFeed().models){ _ in }
        store.completeDeletion(with : deletionError)

        
        XCTAssertEqual(store.receivedMessages, [.deletedCachedFeed])
    }
    
    func test_save_requestNewCacheInsetionWithTimeStampOnSuccessfulDeletion() {
        let timestamp = Date()
        let feed = uniqueImageFeed()
       
        let (sut , store) = makeSUT(currentDate: { timestamp })
        
        sut.save(feed.models){ _ in }
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages, [.deletedCachedFeed, .insert(feed.local, timestamp)])
        
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
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().models, completion: {receivedResults.append($0)})
        
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        
        let store = FeedStoreSpy()
        var sut : LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().models, completion: {receivedResults.append($0)})
        
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
        sut.save(uniqueImageFeed().models) { error in
            receivedError = error
            exp.fulfill()
        }
        
        
        action()
        wait(for: [exp] , timeout: 1.0)
        
        XCTAssertEqual(receivedError as? NSError, expectedError, file: file, line: line)
    }
    
    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), url: anyURL(), description: "any", location: "any")
    }
    
    private func uniqueImageFeed() -> (models : [FeedImage] , local: [LocalFeedImage]) {
        let items = [uniqueImage() , uniqueImage()]
        let localItems = items.map({ LocalFeedImage(id: $0.id, url: $0.url, description: $0.description, location: $0.location)})
        return (items, localItems)
    }
    
  
    
    
     
}

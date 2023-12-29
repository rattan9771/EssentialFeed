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
    
    //MARK:- HELPER
    
    private func makeSUT(currentDate: (@escaping () -> Date) = Date.init , file: StaticString = #file,line: UInt = #line) -> (sut : LocalFeedLoader, store : FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate : currentDate)
        trackMemoryLeak(store, file: file, line: line)
        trackMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }
    
    
    private class FeedStoreSpy : FeedStore {
        
        typealias DeletionCompletion = (Error?) -> Void
        typealias InsertionCompletion = (Error?) -> Void
        
        private var deletionCompletion =  [DeletionCompletion]()
        private var insertionCompletion = [InsertionCompletion]()
        enum ReceivedMessage : Equatable {
            case deletedCachedFeed
            case insert([LocalFeedImage] , Date)
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
        
        func insert(_ feed : [LocalFeedImage], timestamp: Date, completion : @escaping InsertionCompletion ) {
            insertionCompletion.append(completion)
            receivedMessages.append(.insert(feed, timestamp))
        }
        
        func completeInsertion(with error : Error, at index : Int = 0 ) {
            insertionCompletion[index](error)
        }
        
        func completeInsertionSuccessfully( at index : Int = 0 ) {
            insertionCompletion[index](nil)
        }
    }

}

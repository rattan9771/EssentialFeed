//
//  Helper.swift
//  EssentialFeedTests
//
//  Created by Rattan Das on 29/12/23.
//

import Foundation
import EssentialFeed

 class FeedStoreSpy : FeedStore {
    
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    private var deletionCompletion =  [DeletionCompletion]()
    private var insertionCompletion = [InsertionCompletion]()
    enum ReceivedMessage : Equatable {
        case deletedCachedFeed
        case insert([LocalFeedImage] , Date)
        case retrieve
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
     
     func retrieve() {
         receivedMessages.append(.retrieve)
     }
}

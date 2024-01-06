//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Rattan Das on 01/01/24.
//

import Foundation
import EssentialFeed



 func uniqueImageFeed() -> (models : [FeedImage] , local: [LocalFeedImage]) {
    let items = [uniqueImage() , uniqueImage()]
    let localItems = items.map({ LocalFeedImage(id: $0.id, url: $0.url, description: $0.description, location: $0.location)})
    return (items, localItems)
}

 func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), url: anyURL(), description: "any", location: "any")
}

public extension Date {
    
    func minusFeedCacheMaxAge() -> Date {
        return self.adding(days: -feedCacheMaxAgeInDays)
    }
    
    private var feedCacheMaxAgeInDays : Int {
        return 7
    }
    
    private func adding(days : Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}

extension Date {
    
    func adding(seconds : Int) -> Date {
        return self + TimeInterval(seconds)
    }
}

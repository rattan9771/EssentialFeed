//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Rattan Das on 06/01/24.
//

import Foundation


internal final class FeedCachePolicy {
    
    private init() {}
    
    private static let calender = Calendar(identifier: .gregorian)
    
    private static func maxCacheAge() -> Int {
        return 7
    }
    
    static func validate(_ timestamp : Date, against date : Date) -> Bool {
       guard let maxCacheAge = calender.date(byAdding: .day, value: maxCacheAge(), to: timestamp) else {return false }
        return date < maxCacheAge
    }
}

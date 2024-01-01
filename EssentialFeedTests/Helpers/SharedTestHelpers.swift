//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Rattan Das on 01/01/24.
//

import Foundation

 func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
}

 func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

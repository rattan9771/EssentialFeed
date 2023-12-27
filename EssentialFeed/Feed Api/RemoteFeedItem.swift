//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Rattan Das on 27/12/23.
//

import Foundation
internal struct RemoteFeedItem : Decodable {
    
    internal let id : UUID
    internal let image : URL
    internal let description : String?
    internal let location: String?
    
}

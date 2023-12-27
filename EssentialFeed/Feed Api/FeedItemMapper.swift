//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Rattan on 13/11/23.
//

import Foundation



 class FeedItemMapper {
    
    private struct Root : Decodable {
        let items : [RemoteFeedItem]
    }

    static var OK_200 : Int { return 200 }
   
     
     internal static func map(_ data : Data , from response : HTTPURLResponse) throws-> [RemoteFeedItem] {
         
         guard  response.statusCode == OK_200,
                let root = try? JSONDecoder().decode(Root.self, from: data) else {
             throw RemoteFeedLoader.Error.invalidData
         }
         
         return root.items
     }
}

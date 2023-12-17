//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Rattan on 13/11/23.
//

import Foundation


 class FeedItemMapper {
    
    private struct Root : Decodable {
        let items : [Item]
        
        var feed : [FeedItem] {
            return items.map{ $0.item }
        }
    }


    private struct Item : Decodable {
        
         let id : UUID
         let image : URL
         let description : String?
         let location: String?
        
        var item : FeedItem {
            
            return FeedItem(id: id,
                            imageURL: image,
                            description: description,
                            location: location)
        }
    }
    
    static var OK_200 : Int { return 200 }
    
    static func map(_ data : Data, _ response : HTTPURLResponse) throws -> [FeedItem] {
        
        guard  response.statusCode == OK_200 else {
            throw RemoteFeedLoader.Error.invalidPath
        }
        
        let root = try JSONDecoder().decode(Root.self, from: data)
        
        return root.items.map{ $0.item }
    }
     
     internal static func map(_ data : Data , from response : HTTPURLResponse) -> RemoteFeedLoader.Result {
         
         guard  response.statusCode == OK_200,
                let root = try? JSONDecoder().decode(Root.self, from: data) else {
             return .failure(RemoteFeedLoader.Error.invalidPath)
         }
         
         return (.success(root.feed))
     }
}

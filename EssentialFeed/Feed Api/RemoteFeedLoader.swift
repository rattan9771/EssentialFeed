//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Rattan on 06/11/23.
//

import Foundation


final public class RemoteFeedLoader: FeedLoader {
    
    private let url : URL
    private let client : HTTPClient
    public enum Error : Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = LoadFeedResult
    
    public init(url : URL, client: HTTPClient) {
        self.client = client
        self.url = url
        
    }
    
    public func load(completion : @escaping ((Result) -> Void)  ) {
        client.get(from: url) {[weak self] (result)  in
            
            guard self != nil else {return}
            
            switch result {
                
            case let .success(data, response):
                
                completion(RemoteFeedLoader.map(data, response))
                
                
            case .failure:
                completion(.failure(Error.connectivity))
            }
          
           
        }
        
    }
    
    private static func map(_ data : Data , _ response : HTTPURLResponse ) -> Result {
        do {
            let item = try FeedItemMapper.map(data, from: response)
            return (.success(item.toModels()) )
        }catch {
            return (.failure(error))
        }
    }
    
   
}



private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedItem ] {
        map { FeedItem(id: $0.id, imageURL: $0.image, description: $0.description, location: $0.location)}
    }
}

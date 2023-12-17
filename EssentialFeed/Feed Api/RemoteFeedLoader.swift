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
        case invalidPath
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
                
                print(response)
                completion(FeedItemMapper.map(data, from: response))
                
                
            case .failure:
                completion(.failure(Error.connectivity))
            }
          
           
        }
        
    }
    
   
}




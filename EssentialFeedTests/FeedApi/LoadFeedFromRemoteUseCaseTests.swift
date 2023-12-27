//
//  LoadFeedFromRemoteUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Rattan Das on 17/12/23.
//

import XCTest
import EssentialFeed

final class LoadFeedFromRemoteUseCaseTests: XCTestCase {
    
    override func setUpWithError() throws {}

    override func tearDownWithError() throws {
        
        
    }

    func testExample() throws {}

    //MARK:- Start
    
    
    
    
    func test_init_doesNotRequestedUrl() {
        
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestedDataFromUrl() {
  
        let (sut, client) = makeSUT()
        
        sut.load{ _  in}
        
        XCTAssertTrue(!client.requestedURLs.isEmpty)
    }
    
    func test_load_requestedDataFromUrlAndMatch() {
        
        let url = URL(string: "https://www.a-given-url.com")!
       
        let (sut, client) = makeSUT(url: url)
        
        sut.load{ _  in}
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestedDataFromUrlTwice() {
        
        let url = URL(string: "https://www.a-given-url.com")!
     
        let (sut, client) = makeSUT(url: url)
        
        sut.load{ _  in}
        sut.load{ _  in}
                
        XCTAssertEqual(client.requestedURLs , [url , url ])
        
    }
    
    func test_load_deliverErrorOnClientError() {
        
        let (sut , client) = makeSUT()
      
        expect(sut, toCompleteWithResult: failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            // client.completions[0](clientError)
             
             client.complete(with : clientError)
        }
    }
    
    
    
    func test_load_deliverErrorOnNon200HTTPError() {
        
        let (sut , client) = makeSUT()
       
        let samples = [199 , 201 , 300 , 400 , 500 ]
        
        samples.enumerated().forEach { (index , code) in

            
            expect(sut, toCompleteWithResult: failure(.invalidData)) {
                
                let json = makeItemJSON([])
                
                client.complete(withStatusCode: code, index: index, data: json)
            }
        }
        
       
    }
    
    func test_load_deliverErrorOn200HTTPErrorWithInvalidData() {
        
        let (sut , client) = makeSUT()
        
        expect(sut, toCompleteWithResult: failure(.invalidData)) {
            let invalidJson = "Invalid data".data(using: .utf8)!
            
            client.complete(withStatusCode : 200, data : invalidJson)
            
            
        }
        
        /*
        
        var capturedErrors = [RemoteFeedLoader.Error]()
        
        
        sut.load {
            capturedErrors.append($0)
        }
        
        let invalidJson = "Invalid data".data(using: .utf8)!
        
        client.complete(withStatusCode : 200, data : invalidJson)
        
        XCTAssertEqual(capturedErrors, [.invalidPath])
         */
    }
    
    func test_load_deliverNoItemsOn200HTTPResponseWithEmptyJSONList() {
        
        let (sut , client) = makeSUT()
        
   //     var capturedResults = [RemoteFeedLoader.Result]()
        
        
//        sut.load {
//            capturedResults.append($0)
//        }
//
        let emptyJson = "{\"items\" : []}".data(using: .utf8)!
        
      //  client.complete(withStatusCode : 200, data : emptyJson)
        
   //     XCTAssertEqual(capturedResults, [.success([])])
        
        expect(sut, toCompleteWithResult: .success([])) {
            
            client.complete(withStatusCode: 200, data: emptyJson)
        }
    }
    
    func test_load_deliverNoItemsOn200HTTPResponseWithJSONItems() {
        
        let (sut , client) = makeSUT()
        
        
        let item1  = makeItem(id: UUID(),
                              imageURL: URL(string: "http://www.ok.com")!)
     
        
        let item2  = makeItem(id: UUID(),
                              description: "a description", location: "a location", imageURL: URL(string: "https://www.a-url.com")!)
     
        
        
        expect(sut, toCompleteWithResult: .success([ item1.model , item2.model])) {
            
            let json = makeItemJSON([ item1.json ,  item2.json   ])
            
            
            client.complete(withStatusCode: 200, data: json)
        }
        
      //  XCTAssertEqual(capturedResults, [.success([])])
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        
        let url = URL(string: "https://a-url.com")!
        let client = HTTPClientSpy()
        var sut : RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResult = [RemoteFeedLoader.Result]()
        sut?.load{
            capturedResult.append($0)
        }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemJSON([]))
        
        XCTAssertTrue(capturedResult.isEmpty)
    }
    
    //MARK:- HELPER
    
    func makeItemJSON(_ items : [[String:Any]]) -> Data {
        
        let json = [ "items" : items ]
        
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeItem(id : UUID , description : String? = nil , location : String? = nil , imageURL : URL) -> (model :FeedImage, json : [String:Any]) {
        
        let item = FeedImage(id: id, url: imageURL, description: description, location: location)
        
        let json = [
        
            "id" : id.uuidString,
            "description" : description,
            "location" : location,
            "image" : imageURL.absoluteString
        
        ].reduce(into: [String:Any]()) { acc, e in
             let value = e.value
            acc[e.key] = value
        }
        
        return (item, json)
    }
    
    private func makeSUT(url : URL = URL(string: "https://www.a-url.com")!, file : StaticString =  #file, line : UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        
        trackMemoryLeak(sut,file: file, line: line)
        trackMemoryLeak(client,file: file, line: line)
       
        
       return (sut , client)
        
    }
     
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        
        return .failure(error)
    }
    
    /*
     private func trackMemoryLeak(_ instance : AnyObject, file : StaticString = #file, line : UInt = #line){
         
         addTeardownBlock {[weak instance] in
             XCTAssertNil(instance , "Potential memory leak", line: line)
         }
     }
     */
    
    
    
    private func expect(_ sut : RemoteFeedLoader , toCompleteWithResult expectedResult: RemoteFeedLoader.Result , when action : (() -> Void), file : StaticString =  #file, line : UInt = #line ) {
        
        let exp = expectation(description: "wait for load completion")
        
        sut.load { receivedResult in
        
            switch (receivedResult, expectedResult) {
                
            case let (.success(receivedItems) , .success(expectedItems) ):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
                
            case let (.failure(receivedError as RemoteFeedLoader.Error) , .failure(expectedError as RemoteFeedLoader.Error)  ):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
       action()
        
        wait(for: [exp], timeout: 1.0)
        
        /*
        var capturedResults = [RemoteFeedLoader.Result]()
        
        
        sut.load {
            capturedResults.append($0)
        }
        
        action()
        
        XCTAssertEqual(capturedResults, [result], line: line)
         */
    }
    
    
    private class HTTPClientSpy : HTTPClient {
     //   var requestedURLs = [URL]()
      //  var error : Error?
     //   var completions = [((Error) -> Void)]()
        
        private var messages = [(url : URL , completion : ((HTTPClientResult) -> Void) )]()
        
        var requestedURLs : [URL]  {
            return messages.map {$0.url}
        }
        
        func get(from url : URL, completion : @escaping ((HTTPClientResult) -> Void) ) {
            
//            if let error = error {
//                completion(error)
//            }
            
            messages.append((url ,  completion))
            
           // completions.append(completion)
            
            // requestedURLs.append(url)
        }
        
        func complete(with error : Error, index : Int = 0) {
            
            messages[index].completion(.failure(error))
           // completions[index](error)
        }
        
        func complete(withStatusCode code : Int, index : Int = 0, data : Data) {
            
            let response = HTTPURLResponse(url: requestedURLs[0],
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            
            messages[index].completion(.success(data , response))
        }
    }

}

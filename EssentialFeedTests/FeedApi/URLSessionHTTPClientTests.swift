//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Rattan Das on 17/12/23.
//

import XCTest
import EssentialFeed

final class URLSessionHTTPClientTests: XCTestCase {

    override func setUpWithError() throws {
        URLProtocolStub.startInterseptingRequests()
    }

    override func tearDownWithError() throws {
        URLProtocolStub.stopInterseptingRequests()
    }

    func testExample() throws {}
    
    func test_getFromURL_performGETRequestWithURL() {
        
        let url = anyURL()
        let exp = expectation(description: "wait for completion")
        
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
       
    }
    
    func test_getFromURL_failOnRequestError() {
        
        let requestError = anyNSError()
       let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)
        
        XCTAssertEqual( (receivedError as? NSError)?.domain, requestError.domain)
        XCTAssertEqual((receivedError as? NSError)?.code, requestError.code)
        
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        let receivedValues = resultValueFor(data: data, response: response, error: nil)
        
        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response?.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response?.statusCode)
    }
    
    func test_getFromURL_succeedWithEmptyDataOnHTTPURLResponseWithNilData() {
      
        let response = anyHTTPURLResponse()
        let receivedValues = resultValueFor(data: nil, response: response, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response?.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response?.statusCode)
    }

    
    func test_getFromURL_failOnAllInvalidRepresentationCases() {
        
         XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
        
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse? {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)
    }
    
    private func anyData() -> Data {
        return "any data".data(using: .utf8)!
    }
   
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    
     private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
         let sut = URLSessionHTTPClient()
        
         trackMemoryLeak(sut, file: file , line: line)
         
         return sut
     }
    
    private func resultValueFor(data : Data?, response : URLResponse? , error : Error?, file: StaticString = #file, line: UInt = #line) -> (data :  Data, response : HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error)
        switch result {
        case let .success(data, response):
            return (data, response)
        default:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    
    private func resultErrorFor(data : Data?, response : URLResponse? , error : Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        
        let result = resultFor(data: data, response: response, error: error)
        
        switch result {
        case let .failure(error):
            return error
        default:
            XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
        
    }
    
    private func resultFor(data : Data? , response: URLResponse? , error : Error?, file: StaticString = #file, line : UInt = #line) -> HTTPClientResult {
        URLProtocolStub.stubs(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "wait for completion")
        
        var receivedResult : HTTPClientResult!
        sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    private func anyURL() -> URL {
        
        return URL(string: "https://any-url.com")!
    }
     
    
   
    private class URLProtocolStub : URLProtocol {
        
        private static var stubs : Stub?
        
        private static var requestObserver : ((URLRequest) -> Void)?
        
        private  struct Stub {
            let data : Data?
            let response : URLResponse?
            let error : Error?
        }
        
        static func stubs(data : Data?, response : URLResponse?,  error: Error? ) {
                stubs = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequest(observer: @escaping((URLRequest) -> Void) ) {
            
            requestObserver = observer
        }
        
        static func startInterseptingRequests() {
            
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterseptingRequests() {
            
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stubs = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            
            if let requestObserver = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }
            
            if let data = URLProtocolStub.stubs?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stubs?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stubs?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
            
        }
        
        override func stopLoading() {}
    }
    
  
}

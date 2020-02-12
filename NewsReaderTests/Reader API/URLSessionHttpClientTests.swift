//
//  URLSessionHttpClientTests.swift
//  NewsReaderTests
//
//  Created by Soheil on 10/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest
import NewsReader

class URLSessionHttpClient {
	private let session: URLSession

	init(session: URLSession = .shared) {
		self.session = session
	}

	struct UnexpectedValuesRepresentation: Error {}

	func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
		session.dataTask(with: url) { (_, _, error) in
			if let error = error {
				completion(.failure(error))
			} else {
				completion(.failure(UnexpectedValuesRepresentation()))
			}
		}.resume()
	}
}

class URLSessionHttpClientTests: XCTestCase {

	override func setUp() {
		super.setUp()

 		URLProtocolStub.startInterceptingRequest()
	}

	override func tearDown() {
		super.tearDown()

 		URLProtocolStub.stopInterceptingRequest()
	}

	func test_getFromURL_performsGETRequestWithURL() {
 		let url = anyUrl()
 		let exp = expectation(description: "Wait for request")

 		URLProtocolStub.observeRequests { request in
 			XCTAssertEqual(request.url, url)
 			XCTAssertEqual(request.httpMethod, "GET")
 			exp.fulfill()
 		}

 		makeSUT().get(from: url) { _ in }

 		wait(for: [exp], timeout: 1.0)
 	}

	func test_getFromURL_failsOnRequestError() {
		let requestError = anyNSError()

		let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)

		XCTAssertEqual(receivedError as NSError?, requestError)
	}

	func test_getFromURL_failsOnAllInvalidRepresentationCases() {
 		XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
		XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
 		XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: nil))
 		XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
 		XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
 		XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
 		XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
 		XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
 		XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
 		XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
 	}

	// MARK: - Helpers

	private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHttpClient {
		let sut = URLSessionHttpClient()
		trackMemoryLeak(sut, file: file, line: line)

		return sut
	}

	private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
		URLProtocolStub.stub(data: data, response: response, error: error)
		let sut = makeSUT(file: file, line: line)
		let exp = expectation(description: "Wait for completion")

		var receivedError: Error?
		sut.get(from: anyUrl()) { result in
			switch result {
			case let .failure(error):
				receivedError = error
			default:
				XCTFail("Expected failure, got \(result) instead", file: file, line: line)
			}

			exp.fulfill()
		}

		wait(for: [exp], timeout: 1.0)
		return receivedError
	}


	private func anyUrl() -> URL {
		return URL(string: "https://a-url.com")!
	}

	private func anyData() -> Data {
 		return Data(bytes: "any data".utf8)
 	}

 	private func anyNSError() -> NSError {
 		return NSError(domain: "any error", code: 0)
 	}

 	private func anyHTTPURLResponse() -> HTTPURLResponse {
 		return HTTPURLResponse(url: anyUrl(), statusCode: 200, httpVersion: nil, headerFields: nil)!
 	}

 	private func nonHTTPURLResponse() -> URLResponse {
 		return URLResponse(url: anyUrl(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
 	}


	private class URLProtocolStub: URLProtocol {
		private static var stub: Stub?
		private static var requestObserver: ((URLRequest) -> Void)?


		private struct Stub {
			let data: Data?
			let response: URLResponse?
			let error: Error?
		}

		static func observeRequests(observer: @escaping (URLRequest) -> Void) {
 			requestObserver = observer
 		}

		static func stub(data: Data?, response: URLResponse?,  error: Error?) {
			stub = Stub(data: data, response: response, error: error)
		}

		static func startInterceptingRequest() {
			URLProtocol.registerClass(URLProtocolStub.self)
		}

		static func stopInterceptingRequest() {
			URLProtocol.unregisterClass(URLProtocolStub.self)
			requestObserver = nil
			stub = nil
		}

		override class func canInit(with request: URLRequest) -> Bool {
			requestObserver?(request)
			return true
		}

		override class func canonicalRequest(for request: URLRequest) -> URLRequest {
			return request
		}

		override func startLoading() {
			if let error = URLProtocolStub.stub?.error {
				client?.urlProtocol(self, didFailWithError: error)
			}

			if let data = URLProtocolStub.stub?.data {
				client?.urlProtocol(self, didLoad: data)
			}

			if let response = URLProtocolStub.stub?.response {
				client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
			}

			client?.urlProtocolDidFinishLoading(self)
		}

		override func stopLoading() {}
	}

}

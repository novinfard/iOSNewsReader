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

	func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
		session.dataTask(with: url) { (_, _, error) in
			if let error = error {
				completion(.failure(error))
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
 		let url = URL(string: "http://any-url.com")!
 		let exp = expectation(description: "Wait for request")

 		URLProtocolStub.observeRequests { request in
 			XCTAssertEqual(request.url, url)
 			XCTAssertEqual(request.httpMethod, "GET")
 			exp.fulfill()
 		}

 		makeSUT().get(from: url) { _ in }

 		wait(for: [exp], timeout: 1.0)
 	}

	func test_getFromUrl_failOnRequestError() {
		let url = URL(string: "https://a-url.com")!
		let error = NSError(domain: "Domain error", code: 1)
		URLProtocolStub.stub(data: nil, response: nil, error: error)

		let sut = makeSUT()

		let exp = expectation(description: "wait for completion")
		sut.get(from: url) { result in
			switch result {
			case let .failure(receivedError as NSError):
				XCTAssertEqual(receivedError, error)
			default:
				XCTFail("Expected failure with error \(error), get \(result) instead")
			}
			exp.fulfill()
		}

		wait(for: [exp], timeout: 1.0)
	}

	// MARK: - Helpers

	private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHttpClient {
		let sut = URLSessionHttpClient()
		trackMemoryLeak(sut, file: file, line: line)

		return sut
	}

	private func trackMemoryLeak(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should be deallocated - potential retain cycle", file: file, line: line)
		}
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

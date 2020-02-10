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

	func test_getFromUrl_failOnRequestError() {
		URLProtocolStub.startInterceptingRequest()

		let url = URL(string: "https://a-url.com")!
		let error = NSError(domain: "Domain error", code: 1)
		URLProtocolStub.stub(url: url, data: nil, response: nil, error: error)

		let sut = URLSessionHttpClient()

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

		URLProtocolStub.stopInterceptingRequest()
	}

	// MARK: - Helpers

	private class URLProtocolStub: URLProtocol {
		private static var stubs = [URL: Stub]()

		private struct Stub {
			let data: Data?
			let response: URLResponse?
			let error: Error?
		}

		static func stub(url: URL, data: Data?, response: URLResponse?,  error: Error?) {
			stubs[url] = Stub(data: data, response: response, error: error)
		}

		static func startInterceptingRequest() {
			URLProtocol.registerClass(URLProtocolStub.self)
		}

		static func stopInterceptingRequest() {
			URLProtocol.unregisterClass(URLProtocolStub.self)
			stubs = [:]
		}

		override class func canInit(with request: URLRequest) -> Bool {
			guard let url = request.url else { return false }

			return URLProtocolStub.stubs[url] != nil
		}

		override class func canonicalRequest(for request: URLRequest) -> URLRequest {
			return request
		}

		override func startLoading() {
			guard let url = request.url,
				let stub = URLProtocolStub.stubs[url] else {
					return
			}

			if let error = stub.error {
				client?.urlProtocol(self, didFailWithError: error)
			}

			if let data = stub.data {
				client?.urlProtocol(self, didLoad: data)
			}

			if let response = stub.response {
				client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
			}

			client?.urlProtocolDidFinishLoading(self)
		}

		override func stopLoading() {}
	}

}

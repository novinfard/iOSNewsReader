//
//  URLSessionHttpClientTests.swift
//  NewsReaderTests
//
//  Created by Soheil on 10/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest
import NewsReader

protocol HTTPSession {
	func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
	func resume()
}

class URLSessionHttpClient {
	private let session: HTTPSession

	init(session: HTTPSession) {
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

	func test_getFromUrl_resumeDataTaskWithUrl() {
		let url = URL(string: "https://a-url.com")!
		let session = HTTPSessionSpy()
		let task = URLSessionDataTaskSpy()
		session.stub(url: url, task: task)

		let sut = URLSessionHttpClient(session: session)
		sut.get(from: url) { _ in }

		XCTAssertEqual(task.resumeCallCount, 1)
	}

	func test_getFromUrl_failOnRequestError() {
		let url = URL(string: "https://a-url.com")!
		let session = HTTPSessionSpy()
		let error = NSError(domain: "Domain error", code: 1)
		session.stub(url: url, error: error)

		let sut = URLSessionHttpClient(session: session)

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

	private class HTTPSessionSpy: HTTPSession {
		private var stubs = [URL: Stub]()

		private struct Stub {
			let task: HTTPSessionTask
			let error: Error?
		}

		func stub(url: URL, task: HTTPSessionTask = FakeURLSessionDataTask(), error: Error? = nil) {
			stubs[url] = Stub(task: task, error: error)
		}

		func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
			guard let stub = stubs[url] else {
				fatalError("couldn't find stub for \(url)")
			}
			completionHandler(nil, nil, stub.error)
			return stub.task
		}
	}

	private class FakeURLSessionDataTask: HTTPSessionTask {
		func resume() {}
	}
	private class URLSessionDataTaskSpy: HTTPSessionTask {
		var resumeCallCount = 0

		func resume() {
			resumeCallCount += 1
		}
	}
}

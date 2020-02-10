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

	init(session: URLSession) {
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
		let session = URLSessionSpy()
		let task = URLSessionDataTaskSpy()
		session.stub(url: url, task: task)

		let sut = URLSessionHttpClient(session: session)
		sut.get(from: url) { _ in }

		XCTAssertEqual(task.resumeCallCount, 1)
	}

	func test_getFromUrl_failOnRequestError() {
		let url = URL(string: "https://a-url.com")!
		let session = URLSessionSpy()
		let task = URLSessionDataTaskSpy()
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

	private class URLSessionSpy: URLSession {
		private var stubs = [URL: Stub]()

		private struct Stub {
			let task: URLSessionDataTask
			let error: Error?
		}

		func stub(url: URL, task: URLSessionDataTask = FakeURLSessionDataTask(), error: Error? = nil) {
			stubs[url] = Stub(task: task, error: error)
		}

		override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
			guard let stub = stubs[url] else {
				fatalError("couldn't find stub for \(url)")
			}
			completionHandler(nil, nil, stub.error)
			return stub.task
		}
	}

	private class FakeURLSessionDataTask: URLSessionDataTask {
		override func resume() {}
	}
	private class URLSessionDataTaskSpy: URLSessionDataTask {
		var resumeCallCount = 0

		override func resume() {
			resumeCallCount += 1
		}
	}
}

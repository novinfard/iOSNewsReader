//
//  URLSessionHttpClientTests.swift
//  NewsReaderTests
//
//  Created by Soheil on 10/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest

class URLSessionHttpClient {
	private let session: URLSession

	init(session: URLSession) {
		self.session = session
	}

	func get(from url: URL) {
		session.dataTask(with: url) { (_, _, _) in }
	}
}

class URLSessionHttpClientTests: XCTestCase {

	func test_getFromUrl_createDataTaskWithUrl() {
		let url = URL(string: "https://a-url.com")!
		let session = URLSessionSpy()

		let sut = URLSessionHttpClient(session: session)
		sut.get(from: url)

		XCTAssertEqual(session.receivedURLs, [url])
	}

	// MARK: - Helpers

	private class URLSessionSpy: URLSession {
		var receivedURLs = [URL]()

		override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
			receivedURLs.append(url)
			return FakeURLSessionDataTask()
		}
	}

	private class FakeURLSessionDataTask: URLSessionDataTask {}
}

//
//  RemoteNewsReaderTest.swift
//  NewsReaderTests
//
//  Created by Soheil on 06/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest
import NewsReader

class RemoteNewsReaderTest: XCTestCase {

	func test_init_doesNotRequestDataFromUrl() {
		// Given
		let (_, client) = makeSut()

		// When
		// Nothing requested

		// Then
		XCTAssertNil(
			client.requestedUrl,
			"As we didn't request the data, the url of our HTTP client should be nil"
		)
	}

	func test_load_requestsDataFromUrl() {
		// Given
		let url = URL(string: "https://a-sample-given-url.com")!
		let (sut, client) = self.makeSut(url: url)

		// When
		sut.load()

		// Then
		XCTAssertEqual(client.requestedUrl, url)
	}

	func test_loadTwice_requestsDataFromUrlTwice() {
		// Given
		let url = URL(string: "https://a-sample-given-url.com")!
		let (sut, client) = self.makeSut(url: url)

		// When
		sut.load()
		sut.load()

		// Then
		XCTAssertEqual(client.requestedUrls, [url, url])
	}


}

// Mark: - Helpers
extension RemoteNewsReaderTest {
	private func makeSut(url: URL = URL(string: "https://a-sample-url.com")!) -> (sut: RemoteNewsReader, client: HTTPClientSpy) {
		let client = HTTPClientSpy()
		let sut = RemoteNewsReader(url: url, client: client)
		return (sut, client)
	}

	private class HTTPClientSpy: HTTPClient {
		var requestedUrl: URL?
		var requestedUrls = [URL]()

		func get(from url: URL) {
			self.requestedUrl = url
			self.requestedUrls.append(url)

		}
	}
}

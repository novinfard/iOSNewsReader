//
//  RemoteNewsReaderTest.swift
//  NewsReaderTests
//
//  Created by Soheil on 06/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest

class RemoteNewsReader {
	private let url: URL
	private let client: HTTPClient

	init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	func load() {
		client.get(from: url)
	}

}

protocol HTTPClient {
	func get(from url: URL)
}

class HTTPClientSpy: HTTPClient {
	func get(from url: URL) {
		self.requestedUrl = url

	}

	var requestedUrl: URL?

}

class RemoteNewsReaderTest: XCTestCase {

	func test_init_doesNotRequestDataFromUrl() {
		// Given
		let url = URL(string: "https://a-sample-url.com")!
		let client = HTTPClientSpy()
		_ = RemoteNewsReader(url: url, client: client)

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
		let client = HTTPClientSpy()
		let sut = RemoteNewsReader(url: url, client: client)

		// When
		sut.load()

		// Then
		XCTAssertEqual(client.requestedUrl, url)
	}

}

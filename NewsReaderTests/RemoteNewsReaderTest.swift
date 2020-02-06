//
//  RemoteNewsReaderTest.swift
//  NewsReaderTests
//
//  Created by Soheil on 06/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest

class RemoteNewsReader {
	private let client: HTTPClient

	init(client: HTTPClient) {
		self.client = client
	}

	func load() {
		client.get(from: URL(string: "https://a-sample-url.com")!)
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
		let client = HTTPClientSpy()
		_ = RemoteNewsReader(client: client)

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
		let client = HTTPClientSpy()
		let sut = RemoteNewsReader(client: client)

		// When
		sut.load()

		// Then
		XCTAssertNotNil(client.requestedUrl)
	}

}

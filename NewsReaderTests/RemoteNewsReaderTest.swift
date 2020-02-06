//
//  RemoteNewsReaderTest.swift
//  NewsReaderTests
//
//  Created by Soheil on 06/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest

class RemoteNewsReader {
	func load() {
		HTTPClient.shared.requestedUrl = URL(string: "https://a-sample-url.com")
	}

}

class HTTPClient {
	static let shared = HTTPClient()

	private init() {}

	var requestedUrl: URL?
}

class RemoteNewsReaderTest: XCTestCase {

	func test_init_doesNotRequestDataFromUrl() {
		// Given
		let client = HTTPClient.shared
		_ = RemoteNewsReader()

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
		let client = HTTPClient.shared
		let sut = RemoteNewsReader()

		// When
		sut.load()

		// Then
		XCTAssertNotNil(client.requestedUrl)
	}

}

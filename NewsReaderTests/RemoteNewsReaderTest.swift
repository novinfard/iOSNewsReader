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
		HTTPClient.shared.get(from: URL(string: "https://a-sample-url.com")!)
	}

}

class HTTPClient {
	static var shared = HTTPClient()

	func get(from url: URL) {}
}

class HTTPClientSpy: HTTPClient {
	override func get(from url: URL) {
		self.requestedUrl = url

	}

	var requestedUrl: URL?

}

class RemoteNewsReaderTest: XCTestCase {

	func test_init_doesNotRequestDataFromUrl() {
		// Given
		let client = HTTPClientSpy()
		HTTPClient.shared = client
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
		let client = HTTPClientSpy()
		HTTPClient.shared = client
		let sut = RemoteNewsReader()

		// When
		sut.load()

		// Then
		XCTAssertNotNil(client.requestedUrl)
	}

}

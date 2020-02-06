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

		func get(from url: URL) {
			self.requestedUrl = url

		}
	}
}

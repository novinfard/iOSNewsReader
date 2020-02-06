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
		XCTAssertTrue(
			client.requestedUrls.isEmpty,
			"As we didn't request the data, the url array of our HTTP client should be empty"
		)
	}

	func test_load_requestsDataFromUrl() {
		// Given
		let url = URL(string: "https://a-sample-given-url.com")!
		let (sut, client) = self.makeSut(url: url)

		// When
		sut.load()

		// Then
		XCTAssertEqual(client.requestedUrls, [url])
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

	func test_load_connectivityErrorRaised() {
		let (sut, client) = self.makeSut()
		client.error = NSError(domain: "Test", code: 0)

		var capturedErrors = [RemoteNewsReader.Error]()
		sut.load { capturedErrors.append($0) }

		XCTAssertEqual(capturedErrors, [.connectivity])
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
		var requestedUrls = [URL]()
		var error: Error?

		func get(from url: URL, completion: (Error) -> Void) {
			if let error = error {
				completion(error)
			}
			self.requestedUrls.append(url)

		}
	}
}

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
		sut.load { _ in }

		// Then
		XCTAssertEqual(client.requestedUrls, [url])
	}

	func test_loadTwice_requestsDataFromUrlTwice() {
		// Given
		let url = URL(string: "https://a-sample-given-url.com")!
		let (sut, client) = self.makeSut(url: url)

		// When
		sut.load { _ in }
		sut.load { _ in }

		// Then
		XCTAssertEqual(client.requestedUrls, [url, url])
	}

	func test_load_connectivityErrorRaised() {
		// Given
		let (sut, client) = self.makeSut()

		// When
		var capturedErrors = [RemoteNewsReader.Error]()
		sut.load { capturedErrors.append($0) }

		let error = NSError(domain: "Test", code: 0)
		client.complete(with: error)

		// Then
		XCTAssertEqual(capturedErrors, [.connectivity])
	}

	func test_load_ErrorRaisedNon200HTTPResponse() {
		// Given
		let (sut, client) = self.makeSut()

		let samples = [199, 200, 300, 400, 403, 404, 500]
		samples.enumerated().forEach { index, error in
			// When
			var capturedErrors = [RemoteNewsReader.Error]()
			sut.load { capturedErrors.append($0) }

			client.complete(withStatusCode: error, at: index)

			// Then
			XCTAssertEqual(capturedErrors, [.invalidData])
		}
	}

	func test_load_invalidJsonErrorRaise() {
		let (sut, client) = self.makeSut()

		var capturedErrors = [RemoteNewsReader.Error]()
		sut.load { capturedErrors.append($0) }

		let invalidJsonData = Data("invalid json".utf8)
		client.complete(withStatusCode: 200, data: invalidJsonData)

		XCTAssertEqual(capturedErrors, [.invalidData])

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

		private var messages = [(url: URL, completions: (HTTPClientResult) -> Void)]()

		var requestedUrls: [URL] {
			self.messages.map({$0.url})
		}

		func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
			self.messages.append((url, completion))
		}

		func complete(with error: Error, at index: Int = 0) {
			self.messages[index].completions(.failure(error))
		}

		func complete(withStatusCode code: Int,
					  data: Data = Data(),
					  at index: Int = 0) {
			let response = HTTPURLResponse(
				url: requestedUrls[index],
				statusCode: code,
				httpVersion: nil,
				headerFields: nil
			)!
			self.messages[index].completions(.success(data, response))
		}
	}
}

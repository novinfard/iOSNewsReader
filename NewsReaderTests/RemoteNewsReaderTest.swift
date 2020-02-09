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
		let (sut, client) = self.makeSut()

		self.expect(sut, toCompleteWith: .failure(.connectivity), when: {
			let error = NSError(domain: "Test", code: 0)
			client.complete(with: error)
		})
	}

	func test_load_ErrorRaisedNon200HTTPResponse() {
		let (sut, client) = self.makeSut()

		let samples = [199, 200, 300, 400, 403, 404, 500]
		samples.enumerated().forEach { index, error in
			self.expect(sut, toCompleteWith: .failure(.invalidData), when: {
				client.complete(withStatusCode: error, at: index)
			})
		}
	}

	func test_load_invalidJsonErrorRaise() {
		let (sut, client) = self.makeSut()

		self.expect(sut, toCompleteWith: .failure(.invalidData), when: {
			let invalidJsonData = Data("invalid json".utf8)
			client.complete(withStatusCode: 200, data: invalidJsonData)
		})
	}

	func test_load_deliverNoItemsOnEmptyListResponse() {
		let (sut, client) = self.makeSut()

		self.expect(sut, toCompleteWith: .success([]), when: {
			let emptyNewsJsonData = Data("""
			{\"status\": \"ok\",
			\"totalResults\": 0,
			\"news\": [] }
			""".utf8)
			client.complete(withStatusCode: 200, data: emptyNewsJsonData)

		})
	}

	func test_load_deliverItemsOnListResponse() {
		let (sut, client) = self.makeSut()

		let news1 = NewsItem(
			id: UUID(),
			source: Source(id: nil, name: "a source"),
			tags: nil,
			author: "an author",
			title: "a title",
			description: "a description",
			urlToImage: nil,
//			publishedAt: Date(),
			content: "a content"
		)

		let news1Json: [String : Any] = [
			"id": news1.id.uuidString,
			"source": ["name": news1.source.name],
			"author": news1.author,
			"title": news1.title,
			"description": news1.description,
//			"publishedAt": news1.publishedAt.iso8601,
			"content": news1.content
		]

		let news2 = NewsItem(
			id: UUID(),
			source: Source(id: UUID(), name: "another source"),
//			tags: [
//				Tag(id: UUID(), name: "a tag"),
//				Tag(id: UUID(), name: "another tag")
//			],
			tags: nil,
			author: "another author",
			title: "another title",
			description: "another description",
			urlToImage: URL(string: "https://a-url.com"),
//			publishedAt: Date(),
			content: "another content"
		)

		let news2Json: [String : Any] = [
			"id": news2.id.uuidString,
			"source": ["id": news2.source.id?.uuidString,
					   "name": news2.source.name],
//			"tags": [
//				[
//					"id": news2.tags![0].id.uuidString,
//					"name": news2.tags![0].name
//				],
//				[
//					"id": news2.tags![1].id.uuidString,
//					"name": news2.tags![1].name
//				]
//			],
			"author": news2.author,
			"title": news2.title,
			"description": news2.description,
			"urlToImage": news2.urlToImage!.absoluteString,
//			"publishedAt": news2.publishedAt.iso8601,
			"content": news2.content
		]

		let responseJson: [String : Any] = [
			"status": "ok",
			"totalResults": 2,
			"news": [news1Json, news2Json]
		]

		print(responseJson)

		self.expect(sut, toCompleteWith: .success([news1, news2]), when: {
			let jsonData = try! JSONSerialization.data(withJSONObject: responseJson)
			client.complete(withStatusCode: 200, data: jsonData)
		})

	}


	func skipped_test_jsonCodable_iso8601() {
		let dates = [Date()] // ["Feb 9, 2020 at 12:55:24 PM"]

		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601withFractionalSeconds
		let data = try! encoder.encode(dates)

		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601withFractionalSeconds
		let decodedDates = try! decoder.decode([Date].self, from: data) // ["Feb 9, 2020 at 12:55:24 PM"]

		XCTAssertEqual(dates, decodedDates)
		// fails with error message: [2020-02-09 12:55:24 +0000]") is not equal to ("[2020-02-09 12:55:24 +0000]"
	}
}

// Mark: - Helpers
extension RemoteNewsReaderTest {
	private func makeSut(url: URL = URL(string: "https://a-sample-url.com")!) -> (sut: RemoteNewsReader, client: HTTPClientSpy) {
		let client = HTTPClientSpy()
		let sut = RemoteNewsReader(url: url, client: client)
		return (sut, client)
	}

	private func expect(_ sut: RemoteNewsReader,
						toCompleteWith result: RemoteNewsReader.Result,
						when action: () -> Void,
						file: StaticString = #file,
						line: UInt = #line) {
		var capturedResults = [RemoteNewsReader.Result]()
		sut.load { capturedResults.append($0) }

		action()

		XCTAssertEqual(
			capturedResults,
			[result],
			file: file,
			line: line
		)
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

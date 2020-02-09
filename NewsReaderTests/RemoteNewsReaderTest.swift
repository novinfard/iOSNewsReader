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

		let samples = [199, 300, 400, 403, 404, 500]
		samples.enumerated().forEach { index, error in
			self.expect(sut, toCompleteWith: .failure(.invalidData), when: {
				let data = self.makeItemsJson([])
				client.complete(withStatusCode: error, data: data, at: index)
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
			let emptyNewsJsonData = self.makeItemsJson([])
			client.complete(withStatusCode: 200, data: emptyNewsJsonData)

		})
	}

	func test_load_deliverItemsOnListResponse() {
		let (sut, client) = self.makeSut()

		let news1 = self.makeItem(
			id: UUID(),
			source: Source(id: nil, name: "a source"),
			author: "an author",
			title: "a title",
			description: "a description",
			urlToImage: nil,
			content: "a content"
		)

		let news2 = self.makeItem(
			id: UUID(),
			source: Source(id: UUID(), name: "another source"),
//			tags: [
//				Tag(id: UUID(), name: "a tag"),
//				Tag(id: UUID(), name: "another tag")
//			],
			author: "another author",
			title: "another title",
			description: "another description",
			urlToImage: URL(string: "https://a-url.com"),
//			publishedAt: Date(),
			content: "another content"
		)

		let responseItems = [news1.model, news2.model]

		self.expect(sut, toCompleteWith: .success(responseItems), when: {
			let jsonData = self.makeItemsJson([news1.json, news2.json])
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
	private func makeSut(url: URL = URL(string: "https://a-sample-url.com")!,
						 file: StaticString = #file,
						 line: UInt = #line) -> (sut: RemoteNewsReader, client: HTTPClientSpy) {
		let client = HTTPClientSpy()
		let sut = RemoteNewsReader(url: url, client: client)

		self.trackMemoryLeak(client, file: file, line: line)
		self.trackMemoryLeak(sut, file: file, line: line)

		return (sut, client)
	}

	private func trackMemoryLeak(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should be deallocated - potential retain cycle", file: file, line: line)
		}
	}

	private func makeItemsJson(_ items: [[String: Any]]) -> Data {
		let responseJson: [String : Any] = [
			"status": "ok",
			"totalResults": items.count,
			"news": items
		]
		return try! JSONSerialization.data(withJSONObject: responseJson)
	}

	private func makeItem(id: UUID,
						  source: Source,
						  author: String,
						  title: String,
						  description: String,
						  urlToImage: URL?,
						  content: String) -> (model: NewsItem, json: [String: Any]) {

		let item = NewsItem(
			id: id,
			source: source,
			tags: nil,
			author: author,
			title: title,
			description: description,
			urlToImage: urlToImage,
			content: content
		)

		let json: [String: Any?] = [
			"id": item.id.uuidString,
			"source": [
				"id": item.source.id?.uuidString,
				"name": item.source.name
			],
			"author": item.author,
			"title": item.title,
			"description": item.description,
			"urlToImage": item.urlToImage?.absoluteString,
			"content": item.content
		]

		let jsonRemovedOptional: [String: Any] = json.reduce(into: [String: Any]()) { (acc, pair) in
			if let value = pair.value {
				acc[pair.key] = value
			}
		}

		return (item, jsonRemovedOptional)
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
					  data: Data,
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

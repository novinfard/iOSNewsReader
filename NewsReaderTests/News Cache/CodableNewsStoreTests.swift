//
//  CodableNewsStoreTests.swift
//  NewsReaderTests
//
//  Created by Soheil on 02/05/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest
import NewsReader

class CodableNewsStore {

	private struct Cache: Codable {
		let news: [CodableNewsItem]
		let timestamp: Date

		var localNews: [LocalNewsItem] {
 			return news.map { $0.local }
 		}
	}

	private struct CodableNewsItem: Codable {
		private let id: Int
		private let source: CodableSourceItem
		private let tags: [CodableTagItem]?
		private let author: String
		private let title: String
		private let description: String
		private let urlToImage: URL?
		private let content: String

		init(_ news: LocalNewsItem) {
			self.id = news.id
			self.source = CodableSourceItem(news.source)
			self.tags = news.tags?.map(CodableTagItem.init)
			self.author = news.author
			self.title = news.title
			self.description = news.description
			self.urlToImage = news.urlToImage
			self.content = news.content
		}

		var local: LocalNewsItem {
			return LocalNewsItem(
				id: id,
				source: source.local,
				tags: tags?.map({ $0.local }),
				author: author,
				title: title,
				description: description,
				urlToImage: urlToImage,
				content: content
			)
		}
	}

	private struct CodableSourceItem: Codable {
		private let id: Int?
		private let name: String

		init(_ source: LocalSourceItem) {
			self.id = source.id
			self.name = source.name
		}

		var local: LocalSourceItem {
			return LocalSourceItem(id: id, name: name)
		}
	}

	private struct CodableTagItem: Codable {
		private let id: Int
		private let name: String

		init(_ tag: LocalTagItem) {
			self.id = tag.id
			self.name = tag.name
		}

		var local: LocalTagItem {
			return LocalTagItem(id: id, name: name)
		}
	}

	private let storeURL: URL

	init(storeURL: URL) {
		self.storeURL = storeURL
	}
	
	func retrieve(completion: @escaping NewsStore.RetrievalCompletion) {
		guard let data = try? Data(contentsOf: storeURL) else {
			return completion(.empty)
		}

		let decoder = JSONDecoder()
		let cache = try! decoder.decode(Cache.self, from: data)
		completion(.found(items: cache.localNews, timestamp: cache.timestamp))
	}

	func insert(_ items: [LocalNewsItem], timestamp: Date, completion: @escaping NewsStore.InsertionCompletion) {
		let encoder = JSONEncoder()
		let cache = Cache(news: items.map(CodableNewsItem.init), timestamp: timestamp)
		let encoded = try! encoder.encode(cache)
		try! encoded.write(to: storeURL)
		completion(nil)
	}
}

class CodableNewsStoreTests: XCTestCase {

	override func setUp() {
		super.setUp()

		setupEmptyStoreState()
	}

	override func tearDown() {
		super.tearDown()

		undoStoreSideEffects()
	}

	func test_retrieve_deliverEmptyOnEmptyCache() {
		let sut = makeSUT()

		expect(sut, toRetrieve: .empty)
	}

	func test_retrieve_hasNoSideEffectOnEmptyCache() {
		let sut = makeSUT()
		let exp = expectation(description: "wait for cach retrieval")

		sut.retrieve { firstResult in
			sut.retrieve { secondResult in
				switch (firstResult, secondResult) {
				case (.empty, .empty):
					break
				default:
					XCTFail("Expected retrieving twice from empty cache to deliver same empty result, got \(firstResult) and \(secondResult) instead")
				}

				exp.fulfill()
			}
		}

		wait(for: [exp], timeout: 1.0)
	}

	func test_retrieveAfterInsertingToEmptyCache_deliverInsertedValues() {
		// given
		let sut = makeSUT()
		let items = uniqueItems().local
		let timestamp = Date()

		// when
		let exp = expectation(description: "wait for cach retrieval")
		sut.insert(items, timestamp: timestamp) { insertionError in
			XCTAssertNil(insertionError, "Expected items to be inserted successfully")
			exp.fulfill()
		}
		wait(for: [exp], timeout: 1.0)

		// then
		expect(sut, toRetrieve: .found(items: items, timestamp: timestamp))
	}

	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
		let sut = makeSUT()
		let items = uniqueItems().local
		let timestamp = Date()
		let exp = expectation(description: "wait for cach retrieval")

		sut.insert(items, timestamp: timestamp) { insertionError in
			XCTAssertNil(insertionError, "Expected items to be inserted successfully")

			sut.retrieve { firstResult in
				sut.retrieve { secondResult in
					switch (firstResult, secondResult) {
					case let (.found(firstFound), .found(secondFound)):
						XCTAssertEqual(firstFound.timestamp, timestamp)
						XCTAssertEqual(firstFound.items, items)

						XCTAssertEqual(secondFound.timestamp, timestamp)
						XCTAssertEqual(secondFound.items, items)
					default:
						XCTFail("Expected retrieving twice from non empty cache to deliver same found result with news \(items) and timestamp \(timestamp), got \(firstResult) and \(secondResult) instead")
					}

					exp.fulfill()
				}			}
		}

		wait(for: [exp], timeout: 1.0)
	}

	// MARK: - Helpers

	private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableNewsStore {
		let sut = CodableNewsStore(storeURL: testSpecificStoreURL())
		trackMemoryLeak(sut, file: file, line: line)
		return sut
	}

	private func testSpecificStoreURL() -> URL {
		return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
	}

	private func expect(_ sut: CodableNewsStore,
						toRetrieve expectedResult: RetrievedCachedNewsResult,
						file: StaticString = #file,
						line: UInt = #line) {

 		let exp = expectation(description: "Wait for cache retrieval")

 		sut.retrieve { retrievedResult in
 			switch (expectedResult, retrievedResult) {
 			case (.empty, .empty):
 				break

 			case let (.found(expected), .found(retrieved)):
 				XCTAssertEqual(retrieved.items, expected.items, file: file, line: line)
 				XCTAssertEqual(retrieved.timestamp, expected.timestamp, file: file, line: line)

 			default:
 				XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
 			}

 			exp.fulfill()
 		}

 		wait(for: [exp], timeout: 1.0)
 	}

	private func setupEmptyStoreState() {
		deleteStoreArtifacts()
	}

	private func undoStoreSideEffects() {
		deleteStoreArtifacts()
	}

	private func deleteStoreArtifacts() {
		try? FileManager.default.removeItem(at: testSpecificStoreURL())
	}
}

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

		do {
			let decoder = JSONDecoder()
			let cache = try decoder.decode(Cache.self, from: data)
			completion(.found(items: cache.localNews, timestamp: cache.timestamp))
		} catch {
			completion(.failure(error))
		}
	}

	func insert(_ items: [LocalNewsItem], timestamp: Date, completion: @escaping NewsStore.InsertionCompletion) {
		do {
			let encoder = JSONEncoder()
			let cache = Cache(news: items.map(CodableNewsItem.init), timestamp: timestamp)
			let encoded = try encoder.encode(cache)
			try encoded.write(to: storeURL)
			completion(nil)
		} catch {
			completion(error)
		}
	}

	func deleteCachedFeed(completion: @escaping NewsStore.DeletionCompletion) {
		guard FileManager.default.fileExists(atPath: storeURL.path) else {
 			return completion(nil)
 		}

 		try! FileManager.default.removeItem(at: storeURL)
		
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

		expect(sut, toRetrieveTwice: .empty)
	}

	func test_retrieve_deliverFoundValuesOnNonEmptyCache() {
		// given
		let sut = makeSUT()
		let items = uniqueItems().local
		let timestamp = Date()

		// when
		insert((items, timestamp: timestamp), to: sut)

		// then
		expect(sut, toRetrieve: .found(items: items, timestamp: timestamp))
	}

	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
		let sut = makeSUT()
		let items = uniqueItems().local
		let timestamp = Date()

		insert((items, timestamp: timestamp), to: sut)

		expect(sut, toRetrieveTwice: .found(items: items, timestamp: timestamp))
	}

	func test_retrieve_deliversFailureOnRetrievalError() {
		let storeURL = testSpecificStoreURL()
		let sut = makeSUT(storeURL: storeURL)

		try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

		expect(sut, toRetrieve: .failure(anyNSError()))
	}

	func test_retrieve_hasNoSideEffectsOnFailure() {
		let storeURL = testSpecificStoreURL()
		let sut = makeSUT(storeURL: storeURL)

		try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

		expect(sut, toRetrieveTwice: .failure(anyNSError()))
	}

	func test_insert_overridesPreviouslyInsertedCacheValues() {
 		let sut = makeSUT()

		let firstInsertionError = insert((uniqueItems().local, Date()), to: sut)
 		XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")

 		let latestItems = uniqueItems().local
 		let latestTimestamp = Date()
 		let latestInsertionError = insert((latestItems, latestTimestamp), to: sut)

 		XCTAssertNil(latestInsertionError, "Expected to override cache successfully")
 		expect(sut, toRetrieve: .found(items: latestItems, timestamp: latestTimestamp))
 	}

	func test_insert_deliversErrorOnInsertionError() {
 		let invalidStoreURL = URL(string: "invalid://store-url")!
 		let sut = makeSUT(storeURL: invalidStoreURL)
 		let items = uniqueItems().local
 		let timestamp = Date()

 		let insertionError = insert((items, timestamp), to: sut)

 		XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
 		expect(sut, toRetrieve: .empty)
 	}

	func test_delete_hasNoSideEffectsOnEmptyCache() {
 		let sut = makeSUT()
 		let exp = expectation(description: "Wait for cache deletion")

 		sut.deleteCachedFeed { deletionError in
 			XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
 			exp.fulfill()
 		}
 		wait(for: [exp], timeout: 1.0)

 		expect(sut, toRetrieve: .empty)
 	}

	func test_delete_emptiesPreviouslyInsertedCache() {
 		let sut = makeSUT()
 		insert((uniqueItems().local, Date()), to: sut)

 		let exp = expectation(description: "Wait for cache deletion")
 		sut.deleteCachedFeed { deletionError in
 			XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
 			exp.fulfill()
 		}
 		wait(for: [exp], timeout: 1.0)

 		expect(sut, toRetrieve: .empty)
 	}

	// MARK: - Helpers

	private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> CodableNewsStore {
		let sut = CodableNewsStore(storeURL: storeURL ?? testSpecificStoreURL())
		trackMemoryLeak(sut, file: file, line: line)
		return sut
	}

	private func testSpecificStoreURL() -> URL {
		return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
	}

	@discardableResult
	private func insert(_ cache: (items: [LocalNewsItem], timestamp: Date),
						to sut: CodableNewsStore) -> Error? {

		let exp = expectation(description: "Wait for cache insertion")
		var insertionError: Error?

 		sut.insert(cache.items, timestamp: cache.timestamp) { receivedInsertionError in
 			insertionError = receivedInsertionError
 			exp.fulfill()
 		}
 		wait(for: [exp], timeout: 1.0)

		return insertionError
 	}

	private func expect(_ sut: CodableNewsStore,
						toRetrieveTwice expectedResult: RetrievedCachedNewsResult,
						file: StaticString = #file,
						line: UInt = #line) {

 		expect(sut, toRetrieve: expectedResult, file: file, line: line)
 		expect(sut, toRetrieve: expectedResult, file: file, line: line)
 	}

	private func expect(_ sut: CodableNewsStore,
						toRetrieve expectedResult: RetrievedCachedNewsResult,
						file: StaticString = #file,
						line: UInt = #line) {

 		let exp = expectation(description: "Wait for cache retrieval")

 		sut.retrieve { retrievedResult in
 			switch (expectedResult, retrievedResult) {
			case (.empty, .empty),
				 (.failure, .failure):
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

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
		let news: [LocalNewsItem]
		let timestamp: Date
	}

	private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("news.store")
	
	func retrieve(completion: @escaping NewsStore.RetrievalCompletion) {
		guard let data = try? Data(contentsOf: storeURL) else {
			return completion(.empty)
		}

		let decoder = JSONDecoder()
		let cache = try! decoder.decode(Cache.self, from: data)
		completion(.found(items: cache.news, timestamp: cache.timestamp))
	}

	func insert(_ items: [LocalNewsItem], timestamp: Date, completion: @escaping NewsStore.InsertionCompletion) {
		let encoder = JSONEncoder()
		let encoded = try! encoder.encode(Cache(news: items, timestamp: timestamp))
		try! encoded.write(to: storeURL)
		completion(nil)
	}
}

class CodableNewsStoreTests: XCTestCase {

	override class func setUp() {
		super.setUp()

		let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("news.store")
		try? FileManager.default.removeItem(at: storeURL)
	}

	override func tearDown() {
		super.tearDown()

		let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("news.store")
		try? FileManager.default.removeItem(at: storeURL)
	}

	func test_retrieve_deliverEmptyOnEmptyCache() {
		let sut = CodableNewsStore()

		let exp = expectation(description: "wait for cach retrieval")
		sut.retrieve { result in
			switch result {
			case .empty:
				break
			default:
				XCTFail("Expected empty result, got \(result) instead")
			}

			exp.fulfill()
		}

		wait(for: [exp], timeout: 1.0)
	}

	func test_retrieve_hasNoSideEffectOnEmptyCache() {
		let sut = CodableNewsStore()

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
		let sut = CodableNewsStore()
		let items = uniqueItems().local
		let timestamp = Date()
		let exp = expectation(description: "wait for cach retrieval")

		sut.insert(items, timestamp: timestamp) { insertionError in
			XCTAssertNil(insertionError, "Expected items to be inserted successfully")

			sut.retrieve { retrieveResult in
				switch retrieveResult {
				case let .found(items: retrievedItems, timestamp: retrievedTimestamp):
					XCTAssertEqual(retrievedTimestamp, timestamp)
					XCTAssertEqual(retrievedItems, items)
				default:
					XCTFail("Expected found with items \(items) and timestamp \(timestamp), got \(retrieveResult) instead")
				}

				exp.fulfill()
			}
		}

		wait(for: [exp], timeout: 1.0)
	}

}

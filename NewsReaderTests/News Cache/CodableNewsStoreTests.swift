//
//  CodableNewsStoreTests.swift
//  NewsReaderTests
//
//  Created by Soheil on 02/05/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest
import NewsReader

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
		let deletionError = deleteCache(from: sut)

 		XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")

 		expect(sut, toRetrieve: .empty)
 	}

	func test_delete_emptiesPreviouslyInsertedCache() {
 		let sut = makeSUT()
 		insert((uniqueItems().local, Date()), to: sut)

		let deletionError = deleteCache(from: sut)

 		XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")

 		expect(sut, toRetrieve: .empty)
 	}

	func test_delete_deliversErrorOnDeletionError() {
 		let noDeletePermissionURL = cachesDirectory()
 		let sut = makeSUT(storeURL: noDeletePermissionURL)

 		let deletionError = deleteCache(from: sut)

 		XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
 		expect(sut, toRetrieve: .empty)
 	}

	func test_storeSideEffects_runSerially() {
		let sut = makeSUT()
		var completedOperationsInOrder = [XCTestExpectation]()

		let op1 = expectation(description: "Operation 1")
		sut.insert(uniqueItems().local, timestamp: Date()) { _ in
			completedOperationsInOrder.append(op1)
			op1.fulfill()
		}

		let op2 = expectation(description: "Operation 2")
		sut.deleteCachedNews() { _ in
			completedOperationsInOrder.append(op2)
			op2.fulfill()
		}

		let op3 = expectation(description: "Operation 3")
		sut.insert(uniqueItems().local, timestamp: Date()) { _ in
			completedOperationsInOrder.append(op3)
			op3.fulfill()
		}

		waitForExpectations(timeout: 5.0)

		XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order")
	}

	// MARK: - Helpers

	private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> NewsStore {
		let sut = CodableNewsStore(storeURL: storeURL ?? testSpecificStoreURL())
		trackMemoryLeak(sut, file: file, line: line)
		return sut
	}

	private func testSpecificStoreURL() -> URL {
		return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
	}
	
	private func cachesDirectory() -> URL {
		return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	}

	@discardableResult
	private func insert(_ cache: (items: [LocalNewsItem], timestamp: Date),
						to sut: NewsStore) -> Error? {

		let exp = expectation(description: "Wait for cache insertion")
		var insertionError: Error?

 		sut.insert(cache.items, timestamp: cache.timestamp) { receivedInsertionError in
 			insertionError = receivedInsertionError
 			exp.fulfill()
 		}
 		wait(for: [exp], timeout: 1.0)

		return insertionError
 	}

	private func deleteCache(from sut: NewsStore) -> Error? {
 		let exp = expectation(description: "Wait for cache deletion")
 		var deletionError: Error?
 		sut.deleteCachedNews { receivedDeletionError in
 			deletionError = receivedDeletionError
 			exp.fulfill()
 		}
 		wait(for: [exp], timeout: 1.0)
 		return deletionError
 	}

	private func expect(_ sut: NewsStore,
						toRetrieveTwice expectedResult: RetrievedCachedNewsResult,
						file: StaticString = #file,
						line: UInt = #line) {

 		expect(sut, toRetrieve: expectedResult, file: file, line: line)
 		expect(sut, toRetrieve: expectedResult, file: file, line: line)
 	}

	private func expect(_ sut: NewsStore,
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

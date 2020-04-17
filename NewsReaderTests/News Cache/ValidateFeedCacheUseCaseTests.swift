//
//  ValidateFeedCacheUseCaseTests.swift
//  NewsReaderTests
//
//  Created by Soheil on 15/04/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest
import NewsReader

class ValidateFeedCacheUseCaseTests: XCTestCase {

	func test_init_doesNotMessageStoreUponCreation() {
		let (_, store) = makeSut()

		XCTAssertEqual(store.receivedMessages, [])
	}

	func test_validateCache_deletesCacheOnRetrievalError() {
		let (sut, store) = makeSut()

		sut.validateCache()
		store.completeRetrieval(with: anyNSError())

		XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedNews])
	}

	func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
		let (sut, store) = makeSut()

		sut.validateCache()
		store.completeRetrievalWithEmptyCache()

		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_validateCache_doesNotDeleteOnNonExpiredCache() {
		let (sut, store) = makeSut()

		let items = uniqueItems()
		let fixedCurrentDate = Date()
		let nonExpiredTimestamp = fixedCurrentDate.minusNewsCacheMaxAge().adding(seconds: 1)

		sut.validateCache()
		store.completeRetrievalWith(items.local, timestamp: nonExpiredTimestamp)

		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_validateCache_deletesCacheOnExpiration() {
		let (sut, store) = makeSut()

		let items = uniqueItems()
		let fixedCurrentDate = Date()
		let expirationTimestamp = fixedCurrentDate.minusNewsCacheMaxAge()

		sut.validateCache()
		store.completeRetrievalWith(items.local, timestamp: expirationTimestamp)

		XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedNews])
	}

	func test_valdiateCache_deletesExpiredCache() {
		let (sut, store) = makeSut()

		let items = uniqueItems()
		let fixedCurrentDate = Date()
		let expiredTimestamp = fixedCurrentDate.minusNewsCacheMaxAge().adding(seconds: -1)

		sut.validateCache()
		store.completeRetrievalWith(items.local, timestamp: expiredTimestamp)

		XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedNews])
	}

	func test_validateCache_doesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDeallocated() {
 		let store = NewsStoreSpy()
		var sut: LocalNewsReader? = LocalNewsReader(store: store, currentDate: Date.init)

 		sut?.validateCache()

 		sut = nil
 		store.completeRetrieval(with: anyNSError())

 		XCTAssertEqual(store.receivedMessages, [.retrieve])
 	}


	// MARK: - Helpers

	private func makeSut(currentDate: @escaping () -> Date = Date.init,
						 file: StaticString = #file,
						 line: UInt = #line) -> (sut: LocalNewsReader, store: NewsStoreSpy) {
		let store = NewsStoreSpy()
		let sut = LocalNewsReader(store: store, currentDate: currentDate)

		trackMemoryLeak(store, file: file, line: line)
		trackMemoryLeak(sut, file: file, line: line)

		return (sut, store)
	}

}

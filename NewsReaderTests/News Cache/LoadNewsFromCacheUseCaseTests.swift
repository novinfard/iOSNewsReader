//
//  LoadNewsFromCacheUseCaseTests.swift
//  NewsReaderTests
//
//  Created by Soheil on 07/04/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest
import NewsReader

class LoadNewsFromCacheUseCaseTests: XCTestCase {
	func test_init_doesNotMessageStoreUponCreation() {
		let (_, store) = makeSut()

		XCTAssertEqual(store.receivedMessages, [])
	}

	func test_load_requestsCatcheRetrieval() {
		let (sut, store) = makeSut()

		sut.load() { _ in }

		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_failsOnRetrievalError() {
		let (sut, store) = makeSut()
		let retrievalError = anyNSError()

		expect(sut, toCompleteWith: .failure(retrievalError), when: {
			store.completeRetrieval(with: retrievalError)
		})
	}

	func test_load_deliversNoNewsOnEmptyCache() {
		let (sut, store) = makeSut()

		expect(sut, toCompleteWith: .success([]), when: {
			store.completeRetrievalWithEmptyCache()
		})
	}

	func test_load_delviersCachedItemOnLessThanSevenDaysOldCache() {
		let items = uniqueItems()
		let fixedCurrentDate = Date()
		let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
		let (sut, store) = makeSut(currentDate: { fixedCurrentDate })

		expect(sut, toCompleteWith: .success(items.models), when: {
			store.completeRetrievalWith(items.local, timestamp: lessThanSevenDaysOldTimestamp)
		})
	}

	func test_load_delviersNoItemsOnSevenDaysOldCache() {
		let items = uniqueItems()
		let fixedCurrentDate = Date()
		let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
		let (sut, store) = makeSut(currentDate: { fixedCurrentDate })

		expect(sut, toCompleteWith: .success([]), when: {
			store.completeRetrievalWith(items.local, timestamp: sevenDaysOldTimestamp)
		})
	}

	func test_load_delviersNoItemsOnMoreThanSevenDaysOldCache() {
		let items = uniqueItems()
		let fixedCurrentDate = Date()
		let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
		let (sut, store) = makeSut(currentDate: { fixedCurrentDate })

		expect(sut, toCompleteWith: .success([]), when: {
			store.completeRetrievalWith(items.local, timestamp: moreThanSevenDaysOldTimestamp)
		})
	}

	func test_load_hasNoSideEffectsOnRetrievalError() {
		let (sut, store) = makeSut()

		sut.load { _ in }
		store.completeRetrieval(with: anyNSError())

		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_hasNoSideEffectsOnEmptyCache() {
		let (sut, store) = makeSut()

		sut.load { _ in }
		store.completeRetrievalWithEmptyCache()

		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_hasNoSideEffectsOnLessThanSevenDaysOldCache() {
		let (sut, store) = makeSut()

		let items = uniqueItems()
		let fixedCurrentDate = Date()
		let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)

		sut.load { _ in }
		store.completeRetrievalWith(items.local, timestamp: lessThanSevenDaysOldTimestamp)

		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_hasNoSideEffectsOnSevenDaysOldCache() {
		let (sut, store) = makeSut()

		let items = uniqueItems()
		let fixedCurrentDate = Date()
		let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)

		sut.load { _ in }
		store.completeRetrievalWith(items.local, timestamp: sevenDaysOldTimestamp)

		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_hasNoSideEffectsOnMoreThanSevenDaysOldCache() {
		let (sut, store) = makeSut()

		let items = uniqueItems()
		let fixedCurrentDate = Date()
		let moreThansevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)

		sut.load { _ in }
		store.completeRetrievalWith(items.local, timestamp: moreThansevenDaysOldTimestamp)

		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_doesNotDeliverResultAfterSUTnstanceHasBeenDeallocated() {
		let store = NewsStoreSpy()
		var sut: LocalNewsReader? = LocalNewsReader(store: store, currentDate: Date.init)

		var receivedResults = [LocalNewsReader.LoadResult]()
		sut?.load {
			receivedResults.append($0)
		}

		sut = nil
		store.completeRetrievalWithEmptyCache()

		XCTAssertTrue(receivedResults.isEmpty)
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

	private func expect(_ sut: LocalNewsReader,
						toCompleteWith expectedResult: LocalNewsReader.LoadResult,
						when acion: () -> Void,
						file: StaticString = #file,
						line: UInt = #line) {
		let exp = expectation(description: "Wait for load completion")

		sut.load() { receivedResult in
			switch (receivedResult, expectedResult) {
			case let (.success(receivedItems), .success(expectedItems)):
				XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
			case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
					XCTAssertEqual(receivedError, expectedError, file: file, line: line)
			default:
				XCTFail("Expected result \(expectedResult), got \(receivedResult) instead")
			}
			exp.fulfill()
		}

		acion()
		wait(for: [exp], timeout: 1.0)
	}
	
}

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

	func test_load_deletesCacheOnRetrievalError() {
		let (sut, store) = makeSut()

		sut.load { _ in }
		store.completeRetrieval(with: anyNSError())

		XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedNews])
	}

	func test_load_doesNotDeleteCacheOnEmptyCache() {
		let (sut, store) = makeSut()

		sut.load { _ in }
		store.completeRetrievalWithEmptyCache()

		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_doesNotDeleteCacheOnLessThanSevenDaysOldCache() {
		let (sut, store) = makeSut()

		let items = uniqueItems()
		let fixedCurrentDate = Date()
		let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)

		sut.load { _ in }
		store.completeRetrievalWith(items.local, timestamp: lessThanSevenDaysOldTimestamp)

		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_deleteCacheOnSevenDaysOldCache() {
		let (sut, store) = makeSut()

		let items = uniqueItems()
		let fixedCurrentDate = Date()
		let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)

		sut.load { _ in }
		store.completeRetrievalWith(items.local, timestamp: sevenDaysOldTimestamp)

		XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedNews])
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

 	private func anyNSError() -> NSError {
 		return NSError(domain: "any error", code: 0)
 	}

	private func anyId() -> Int {
		return Int.random(in: 1 ... 1_000_000)
	}

	private func uniqueItem() -> NewsItem {
		return NewsItem(
			id: anyId(),
			source: Source(id: nil, name: "any"),
			tags: nil,
			author: "any",
			title: "any",
			description: "any",
			urlToImage: URL(string: "https://a-url")!,
			content: "any"
		)
	}

	private func uniqueItems() -> (models: [NewsItem], local: [LocalNewsItem]) {
		let items = [uniqueItem(), uniqueItem()]
		let localItems = items.map {
			return LocalNewsItem(
				id: $0.id,
				source: LocalSourceItem(id: $0.source.id, name: $0.source.name),
				tags: $0.tags?.toLocal(),
				author: $0.author,
				title: $0.title,
				description: $0.description,
				urlToImage: $0.urlToImage,
				content: $0.content
			)
		}
		return (items, localItems)
	}
	
}

private extension Date {
	func adding(days: Int) -> Date {
		return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
	}

	func adding(seconds: TimeInterval) -> Date {
		return self + seconds
	}
}

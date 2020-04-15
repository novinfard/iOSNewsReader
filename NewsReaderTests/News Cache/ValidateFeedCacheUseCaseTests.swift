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

	func test_validateCache_doesNotDeleteOnLessThanSevenDaysOldCache() {
		let (sut, store) = makeSut()

		let items = uniqueItems()
		let fixedCurrentDate = Date()
		let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)

		sut.validateCache()
		store.completeRetrievalWith(items.local, timestamp: lessThanSevenDaysOldTimestamp)

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

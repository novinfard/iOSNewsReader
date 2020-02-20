//
//  CacheNewsUseCaseTests.swift
//  NewsReaderTests
//
//  Created by Soheil on 18/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest
import NewsReader

class LocalNewsReader {
	private let store: NewsStore
	init(store: NewsStore) {
		self.store = store
	}

	func save(_ items: [NewsItem]) {
		store.deleteCachedNews() { [unowned self] error in
			if error == nil {
				self.store.insert(items)
			}
		}
	}
}

class NewsStore {
	typealias DeletionCompletion = (Error?) -> Void
	var deleteCachedNewsCallCount = 0
	var insertCallCount = 0

	private var deletionCompletions = [DeletionCompletion]()
	func deleteCachedNews(completion: @escaping DeletionCompletion) {
		deleteCachedNewsCallCount += 1
		deletionCompletions.append(completion)
	}

	func completeDeletion(with error: Error, at index: Int = 0) {
		deletionCompletions[index](error)
	}

	func completeDeletionSuccessfully(at index: Int = 0) {
		deletionCompletions[index](nil)
	}

	func insert(_ items: [NewsItem]) {
		insertCallCount += 1
	}
}

class CacheNewsUseCaseTests: XCTestCase {

	func test_init_doesNotDeleteCacheUponCreation() {
		let (_, store) = makeSut()

		XCTAssertEqual(store.deleteCachedNewsCallCount, 0)
	}

	func test_save_requestsCacheDeletion() {
		let (sut, store) = makeSut()
		let items = [uniqueItem(), uniqueItem()]
		sut.save(items)

		XCTAssertEqual(store.deleteCachedNewsCallCount, 1)
	}

	func test_save_doesNotRequestCacheInsertionOnDeletionError() {
		let (sut, store) = makeSut()
		let items = [uniqueItem(), uniqueItem()]
		let deletionError = anyNSError()

		sut.save(items)
		store.completeDeletion(with: deletionError)

		XCTAssertEqual(store.insertCallCount, 0)
	}

	func test_save_requestsNewCacheInsertionOnSuccessfullDeletion() {
		let (sut, store) = makeSut()
		let items = [uniqueItem(), uniqueItem()]

		sut.save(items)
		store.completeDeletionSuccessfully()

		XCTAssertEqual(store.insertCallCount, 1)
	}

	// MARK: - Helpers

	private func makeSut(file: StaticString = #file, line: UInt = #line) -> (sut: LocalNewsReader, store: NewsStore) {
		let store = NewsStore()
		let sut = LocalNewsReader(store: store)

		trackMemoryLeak(store, file: file, line: line)
		trackMemoryLeak(sut, file: file, line: line)

		return (sut, store)
	}

	func uniqueItem() -> NewsItem {
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

	private func anyId() -> Int {
		return Int.random(in: 1 ... 1_000_000)
	}

 	private func anyNSError() -> NSError {
 		return NSError(domain: "any error", code: 0)
 	}
}

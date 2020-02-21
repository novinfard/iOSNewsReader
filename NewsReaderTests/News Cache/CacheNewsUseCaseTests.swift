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
	private let currentDate: () -> Date
	init(store: NewsStore, currentDate: @escaping () -> Date) {
		self.store = store
		self.currentDate = currentDate
	}

	func save(_ items: [NewsItem], completion: @escaping (Error?) -> Void) {
		store.deleteCachedNews() { [unowned self] error in
			completion(error)
			if error == nil {
				self.store.insert(items, timestamp: self.currentDate())
			}
		}
	}
}

class NewsStore {
	typealias DeletionCompletion = (Error?) -> Void

	enum ReceivedMessage: Equatable {
		case deleteCachedNews
		case insert([NewsItem], Date)
	}

	private(set) var receivedMessages = [ReceivedMessage]()

	private var deletionCompletions = [DeletionCompletion]()
	func deleteCachedNews(completion: @escaping DeletionCompletion) {
		deletionCompletions.append(completion)
		receivedMessages.append(.deleteCachedNews)
	}

	func completeDeletion(with error: Error, at index: Int = 0) {
		deletionCompletions[index](error)
	}

	func completeDeletionSuccessfully(at index: Int = 0) {
		deletionCompletions[index](nil)
	}

	func insert(_ items: [NewsItem], timestamp: Date) {
		receivedMessages.append(.insert(items, timestamp))
	}
}

class CacheNewsUseCaseTests: XCTestCase {

	func test_init_doesNotMessageStoreUponCreation() {
		let (_, store) = makeSut()

		XCTAssertEqual(store.receivedMessages, [])
	}

	func test_save_requestsCacheDeletion() {
		let (sut, store) = makeSut()
		let items = [uniqueItem(), uniqueItem()]
		sut.save(items) { _ in }

		XCTAssertEqual(store.receivedMessages, [.deleteCachedNews])
	}

	func test_save_doesNotRequestCacheInsertionOnDeletionError() {
		let (sut, store) = makeSut()
		let items = [uniqueItem(), uniqueItem()]
		let deletionError = anyNSError()

		sut.save(items)  { _ in }
		store.completeDeletion(with: deletionError)

		XCTAssertEqual(store.receivedMessages, [.deleteCachedNews])
	}

	func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
		let timestamp = Date()
		let items = [uniqueItem(), uniqueItem()]
		let (sut, store) = makeSut(currentDate: { timestamp } )

		sut.save(items)  { _ in }
		store.completeDeletionSuccessfully()

		XCTAssertEqual(store.receivedMessages, [.deleteCachedNews, .insert(items, timestamp)])
	}

	func test_save_failOnDeletionError() {
		let (sut, store) = makeSut()
		let items = [uniqueItem(), uniqueItem()]
		let deletionError = anyNSError()

		let exp = expectation(description: "Wait for save completion")
		var receivedError: Error?
		sut.save(items) { error in
			receivedError = error
			exp.fulfill()
		}
		store.completeDeletion(with: deletionError)
		wait(for: [exp], timeout: 1)

		XCTAssertEqual(receivedError as NSError?, deletionError)
	}

	// MARK: - Helpers

	private func makeSut(currentDate: @escaping () -> Date = Date.init,
						 file: StaticString = #file,
						 line: UInt = #line) -> (sut: LocalNewsReader, store: NewsStore) {
		let store = NewsStore()
		let sut = LocalNewsReader(store: store, currentDate: currentDate)

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

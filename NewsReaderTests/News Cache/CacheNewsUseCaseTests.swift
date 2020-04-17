//
//  CacheNewsUseCaseTests.swift
//  NewsReaderTests
//
//  Created by Soheil on 18/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest
import NewsReader

class CacheNewsUseCaseTests: XCTestCase {

	func test_init_doesNotMessageStoreUponCreation() {
		let (_, store) = makeSut()

		XCTAssertEqual(store.receivedMessages, [])
	}

	func test_save_requestsCacheDeletion() {
		let (sut, store) = makeSut()
		sut.save(uniqueItems().models) { _ in }

		XCTAssertEqual(store.receivedMessages, [.deleteCachedNews])
	}

	func test_save_doesNotRequestCacheInsertionOnDeletionError() {
		let (sut, store) = makeSut()
		let deletionError = anyNSError()

		sut.save(uniqueItems().models)  { _ in }
		store.completeDeletion(with: deletionError)

		XCTAssertEqual(store.receivedMessages, [.deleteCachedNews])
	}

	func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
		let timestamp = Date()
		let items = uniqueItems()
		let (sut, store) = makeSut(currentDate: { timestamp } )

		sut.save(items.models)  { _ in }
		store.completeDeletionSuccessfully()

		XCTAssertEqual(store.receivedMessages, [.deleteCachedNews, .insert(items.local, timestamp)])
	}

	func test_save_failOnDeletionError() {
		let (sut, store) = makeSut()
		let deletionError = anyNSError()

		expect(sut, toCompleteWithError: deletionError, when: {
			store.completeDeletion(with: deletionError)
		})
	}

	func test_save_failOnInsertionError() {
		let (sut, store) = makeSut()
		let insertionError = anyNSError()

		expect(sut, toCompleteWithError: insertionError, when: {
			store.completeDeletionSuccessfully()
			store.completeInsertion(with: insertionError)

		})

	}

	func test_save_succeedsOnSuccessfulCacheInsertion() {
		let (sut, store) = makeSut()

		expect(sut, toCompleteWithError: nil, when: {
			store.completeDeletionSuccessfully()
			store.completeInsertionSuccessfully()
		})
	}

	func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
		let store = NewsStoreSpy()
		var sut: LocalNewsReader? = LocalNewsReader(store: store, currentDate: Date.init)

		var receivedResults = [LocalNewsReader.SaveResult]()
		sut?.save(uniqueItems().models) { receivedResults.append($0) }

		sut = nil
		store.completeDeletion(with: anyNSError())

		XCTAssertTrue(receivedResults.isEmpty)
	}

	func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
		let store = NewsStoreSpy()
		var sut: LocalNewsReader? = LocalNewsReader(store: store, currentDate: Date.init)

		var receivedResults = [LocalNewsReader.SaveResult]()
		sut?.save(uniqueItems().models) { receivedResults.append($0) }

		store.completeDeletionSuccessfully()
		sut = nil
		store.completeInsertion(with: anyNSError())

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
						toCompleteWithError expectedError: NSError?,
						when action: () -> Void,
						file: StaticString = #file,
						line: UInt = #line){

		let exp = expectation(description: "Wait for save completion")
		var receivedError: Error?
		sut.save(uniqueItems().models) { error in
			receivedError = error
			exp.fulfill()
		}

		action()

		wait(for: [exp], timeout: 1)

		XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
	}
}

extension Array where Element == Tag {
	func toLocal() -> [LocalTagItem] {
		return map {
			LocalTagItem(id: $0.id, name: $0.name)
		}
	}
}

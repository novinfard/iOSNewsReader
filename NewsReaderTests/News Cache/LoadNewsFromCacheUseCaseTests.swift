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
		let exp = expectation(description: "Wait for load completion")

		var receivedError: Error?
		sut.load() { error in
			receivedError = error
			exp.fulfill()
		}

		store.completeRetrieval(with: retrievalError)
		wait(for: [exp], timeout: 1.0)
		XCTAssertEqual(receivedError as NSError?, retrievalError)
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
	
}

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
	func retrieve(completion: @escaping NewsStore.RetrievalCompletion) {
		completion(.empty)
	}
}

class CodableNewsStoreTests: XCTestCase {

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

}

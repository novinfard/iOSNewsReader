//
//  CacheNewsUseCaseTests.swift
//  NewsReaderTests
//
//  Created by Soheil on 18/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest

class LocalNewsReader {
	init(store: NewsStore) {

	}
}

class NewsStore {
	var deleteCachedNewsCallCount = 0
}

class CacheNewsUseCaseTests: XCTestCase {

	func test_init_doesNotDeleteCacheUponCreation() {
		let store = NewsStore()
		_ = LocalNewsReader(store: store)

		XCTAssertEqual(store.deleteCachedNewsCallCount, 0)
	}

}

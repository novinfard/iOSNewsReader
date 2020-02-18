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
		store.deleteCachedNews()
	}
}

class NewsStore {
	var deleteCachedNewsCallCount = 0

	func deleteCachedNews() {
		deleteCachedNewsCallCount += 1
	}
}

class CacheNewsUseCaseTests: XCTestCase {

	func test_init_doesNotDeleteCacheUponCreation() {
		let store = NewsStore()
		_ = LocalNewsReader(store: store)

		XCTAssertEqual(store.deleteCachedNewsCallCount, 0)
	}

	func test_save_requestsCacheDeletion() {
		let store = NewsStore()
		let sut = LocalNewsReader(store: store)
		let items = [uniqueItem(), uniqueItem()]
		sut.save(items)

		XCTAssertEqual(store.deleteCachedNewsCallCount, 1)
	}

	// MARK: - Helpers
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
}

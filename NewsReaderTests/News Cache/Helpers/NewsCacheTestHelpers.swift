 //
//  NewsCacheTestHelpers.swift
//  NewsReaderTests
//
//  Created by Soheil on 15/04/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation
import NewsReader

func anyId() -> Int {
	return Int.random(in: 1 ... 1_000_000)
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

func uniqueItems() -> (models: [NewsItem], local: [LocalNewsItem]) {
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

extension Date {
	func adding(days: Int) -> Date {
		return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
	}

	func adding(seconds: TimeInterval) -> Date {
		return self + seconds
	}
}

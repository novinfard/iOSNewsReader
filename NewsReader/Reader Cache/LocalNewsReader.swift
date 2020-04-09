//
//  LocalNewsReader.swift
//  NewsReader
//
//  Created by Soheil on 04/04/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public final class LocalNewsReader {
	private let store: NewsStore
	private let currentDate: () -> Date

	public typealias SaveResult = Error?
	public typealias LoadResult = NewsReaderResult

	public init(store: NewsStore, currentDate: @escaping () -> Date) {
		self.store = store
		self.currentDate = currentDate
	}

	public func save(_ items: [NewsItem], completion: @escaping (SaveResult) -> Void) {
		store.deleteCachedNews() { [weak self] error in
			guard let self = self else { return }
			if let cacheDeletionError = error {
				completion(cacheDeletionError)
			} else {
				self.cache(items, with: completion)
			}
		}
	}

	public func load(completion: @escaping (LoadResult) -> Void ) {
		store.retrieve { error in
			if let error = error {
				completion(.failure(error))
			}

		}
	}

	private func cache(_ items: [NewsItem], with completion: @escaping (Error?) -> Void) {
		store.insert(items.toLocal(), timestamp: currentDate()) { [weak self] error in
			guard self != nil else { return }
			completion(error)
		}
	}
}

private extension Array where Element == NewsItem {
	func toLocal() -> [LocalNewsItem] {
		return map {
			LocalNewsItem(
				id: $0.id,
				source: $0.source.toLocal,
				tags: $0.tags?.toLocal(),
				author: $0.author,
				title: $0.title,
				description: $0.description,
				urlToImage: $0.urlToImage,
				content: $0.content
			)
		}
	}
}

private extension Array where Element == Tag {
	func toLocal() -> [LocalTagItem] {
		return map {
			LocalTagItem(id: $0.id, name: $0.name)
		}
	}
}

private extension Source {
	var toLocal: LocalSourceItem {
		return LocalSourceItem(id: self.id, name: self.name)
	}
}

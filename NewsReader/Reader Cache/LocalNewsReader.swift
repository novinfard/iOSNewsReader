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
	public init(store: NewsStore, currentDate: @escaping () -> Date) {
		self.store = store
		self.currentDate = currentDate
	}

	public func save(_ items: [NewsItem], completion: @escaping (Error?) -> Void) {
		store.deleteCachedNews() { [weak self] error in
			guard let self = self else { return }
			if let cacheDeletionError = error {
				completion(cacheDeletionError)
			} else {
				self.cache(items, with: completion)
			}
		}
	}

	private func cache(_ items: [NewsItem], with completion: @escaping (Error?) -> Void) {
		store.insert(items, timestamp: currentDate()) { [weak self] error in
			guard self != nil else { return }
			completion(error)
		}
	}
}

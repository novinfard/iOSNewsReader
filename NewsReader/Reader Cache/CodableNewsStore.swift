//
//  CodableNewsStore.swift
//  NewsReader
//
//  Created by Soheil on 09/05/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public class CodableNewsStore: NewsStore {

	private struct Cache: Codable {
		let news: [CodableNewsItem]
		let timestamp: Date

		var localNews: [LocalNewsItem] {
 			return news.map { $0.local }
 		}
	}

	private struct CodableNewsItem: Codable {
		private let id: Int
		private let source: CodableSourceItem
		private let tags: [CodableTagItem]?
		private let author: String
		private let title: String
		private let description: String
		private let urlToImage: URL?
		private let content: String

		init(_ news: LocalNewsItem) {
			self.id = news.id
			self.source = CodableSourceItem(news.source)
			self.tags = news.tags?.map(CodableTagItem.init)
			self.author = news.author
			self.title = news.title
			self.description = news.description
			self.urlToImage = news.urlToImage
			self.content = news.content
		}

		var local: LocalNewsItem {
			return LocalNewsItem(
				id: id,
				source: source.local,
				tags: tags?.map({ $0.local }),
				author: author,
				title: title,
				description: description,
				urlToImage: urlToImage,
				content: content
			)
		}
	}

	private struct CodableSourceItem: Codable {
		private let id: Int?
		private let name: String

		init(_ source: LocalSourceItem) {
			self.id = source.id
			self.name = source.name
		}

		var local: LocalSourceItem {
			return LocalSourceItem(id: id, name: name)
		}
	}

	private struct CodableTagItem: Codable {
		private let id: Int
		private let name: String

		init(_ tag: LocalTagItem) {
			self.id = tag.id
			self.name = tag.name
		}

		var local: LocalTagItem {
			return LocalTagItem(id: id, name: name)
		}
	}

	private let queue = DispatchQueue(label: "\(CodableNewsStore.self)Queue", qos: .userInitiated)
	private let storeURL: URL

	public init(storeURL: URL) {
		self.storeURL = storeURL
	}

	public func retrieve(completion: @escaping RetrievalCompletion) {
		let storeURL = self.storeURL
		queue.async {
			guard let data = try? Data(contentsOf: storeURL) else {
				return completion(.empty)
			}

			do {
				let decoder = JSONDecoder()
				let cache = try decoder.decode(Cache.self, from: data)
				completion(.found(items: cache.localNews, timestamp: cache.timestamp))
			} catch {
				completion(.failure(error))
			}
		}
	}

	public func insert(_ items: [LocalNewsItem], timestamp: Date, completion: @escaping InsertionCompletion) {
		let storeURL = self.storeURL
		queue.async {
			do {
				let encoder = JSONEncoder()
				let cache = Cache(news: items.map(CodableNewsItem.init), timestamp: timestamp)
				let encoded = try encoder.encode(cache)
				try encoded.write(to: storeURL)
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}

	public func deleteCachedNews(completion: @escaping DeletionCompletion) {
		let storeURL = self.storeURL
		queue.async {
			guard FileManager.default.fileExists(atPath: storeURL.path) else {
				return completion(nil)
			}

			do {
				try FileManager.default.removeItem(at: storeURL)
				completion(nil)
			} catch {
				completion(error)
			}
		}
 	}
}

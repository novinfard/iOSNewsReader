//
//  RemoteNewsReader.swift
//  NewsReader
//
//  Created by Soheil on 06/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public final class RemoteNewsReader: NewsReader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public typealias Result = NewsReaderResult

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (Result) -> Void) {
		client.get(from: url, completion: { [weak self] result in
			guard self != nil else { return }
			switch result {
			case let .success(data, response):
				completion(RemoteNewsReader.map(data, response: response))
			case .failure:
				completion(.failure(Error.connectivity))
			}
		})
	}

	private static func map(_ data: Data, response: HTTPURLResponse) -> Result {
		do {
			let items = try NewsItemsMapper.map(data, from: response)
			return .success(items.toModels())
		} catch {
			return .failure(error)
		}
	}
}

private extension Array where Element == RemoteNewsItem {
	func toModels() -> [NewsItem] {
		return map {
			NewsItem(
				id: $0.id,
				source: $0.source.toModel,
				tags: $0.tags?.toModels(),
				author: $0.author,
				title: $0.title,
				description: $0.description,
				urlToImage: $0.urlToImage,
				content: $0.content
			)
		}
	}
}

private extension Array where Element == RemoteTag {
	func toModels() -> [Tag] {
		return map {
			Tag(id: $0.id, name: $0.name)
		}
	}
}

private extension RemoteSource {
	var toModel: Source {
		return Source(id: id, name: name)
	}
}

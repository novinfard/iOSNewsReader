//
//  RemoteNewsReader.swift
//  NewsReader
//
//  Created by Soheil on 06/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public enum HTTPClientResult {
	case success(Data, HTTPURLResponse)
	case failure(Error)
}

public protocol HTTPClient {
	func get(
		from url: URL,
		completion: @escaping (HTTPClientResult) -> Void
	)
}

public final class RemoteNewsReader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public enum Result: Equatable {
		case success([NewsItem])
		case failure(Error)
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (Result) -> Void) {
		client.get(from: url, completion: { result in
			switch result {
			case let .success(data, response):
				if response.statusCode == 200 {
					do {
						let jsonDecoder = JSONDecoder()
						jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
						let response = try jsonDecoder.decode(Response.self, from: data)

						return completion(.success(response.news.map({$0.newsItem})))
					} catch {
						print(error)
						return completion(.failure(.invalidData))
					}
				} else {
					return completion(.failure(.invalidData))
				}
			case .failure:
				completion(.failure(.connectivity))
			}
		})
	}

}

private struct Response: Decodable, Equatable {
	let status: String
	let totalResults: Int
	let news: [ApiNewsItem]

	init(status: String,
				totalResults: Int,
				news: [ApiNewsItem]) {

		self.status = status
		self.totalResults = totalResults
		self.news = news
	}
}

private struct ApiNewsItem: Decodable, Equatable {
	let id: UUID
	let source: ApiSource
	let tags: [ApiTag]?
	let author: String
	let title: String
	let description: String
	let urlToImage: URL?
	let content: String

	var newsItem: NewsItem {
		return NewsItem(
			id: id,
			source: source.source,
			tags: tags?.map({$0.tag}),
			author: author,
			title: title,
			description: description,
			urlToImage: urlToImage,
			content: content
		)
	}
}

private struct ApiSource: Decodable, Equatable {
	let id: UUID?
	let name: String

	init(id: UUID?, name: String) {
		self.id = id
		self.name = name
	}

	var source: Source {
		return Source(id: id, name: name)
	}
}

private struct ApiTag: Decodable, Equatable {
	let id: UUID
	let name: String

	init(id: UUID, name: String) {
		self.id = id
		self.name = name
	}

	var tag: Tag {
		return Tag(id: id, name: name)
	}
}

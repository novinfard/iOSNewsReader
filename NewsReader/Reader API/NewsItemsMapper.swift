//
//  NewsItemsMapper.swift
//  NewsReader
//
//  Created by Soheil on 09/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

internal final class NewsItemsMapper {

	private struct Response: Decodable, Equatable {
		let status: String
		let totalResults: Int
		let news: [ApiNewsItem]

		var items: [NewsItem] {
			return self.news.map({$0.newsItem})
		}

		init(status: String,
					totalResults: Int,
					news: [ApiNewsItem]) {

			self.status = status
			self.totalResults = totalResults
			self.news = news
		}
	}

	private struct ApiNewsItem: Decodable, Equatable {
		let id: Int
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
		let id: Int?
		let name: String

		init(id: Int?, name: String) {
			self.id = id
			self.name = name
		}

		var source: Source {
			return Source(id: id, name: name)
		}
	}

	private struct ApiTag: Decodable, Equatable {
		let id: Int
		let name: String

		init(id: Int, name: String) {
			self.id = id
			self.name = name
		}

		var tag: Tag {
			return Tag(id: id, name: name)
		}
	}

	private static var OK_200: Int { return 200 }

	internal static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteNewsReader.Result {
		guard response.statusCode == OK_200 else {
			return .failure(RemoteNewsReader.Error.invalidData)
		}

		do {
			let jsonDecoder = JSONDecoder()
			jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
			let response = try jsonDecoder.decode(Response.self, from: data)

			return .success(response.items)
		} catch {
			print(error)
			return .failure(RemoteNewsReader.Error.invalidData)
		}
	}

}

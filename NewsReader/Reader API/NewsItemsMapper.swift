//
//  NewsItemsMapper.swift
//  NewsReader
//
//  Created by Soheil on 09/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

internal struct RemoteNewsItem: Decodable, Equatable {
	let id: Int
	let source: RemoteSource
	let tags: [RemoteTag]?
	let author: String
	let title: String
	let description: String
	let urlToImage: URL?
	let content: String
}

internal struct RemoteSource: Decodable, Equatable {
	let id: Int?
	let name: String
}

internal struct RemoteTag: Decodable, Equatable {
	let id: Int
	let name: String
}

internal final class NewsItemsMapper {

	private struct Response: Decodable, Equatable {
		let status: String
		let totalResults: Int
		let news: [RemoteNewsItem]

		init(status: String,
					totalResults: Int,
					news: [RemoteNewsItem]) {

			self.status = status
			self.totalResults = totalResults
			self.news = news
		}
	}

	private static var OK_200: Int { return 200 }

	internal static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteNewsItem] {
		guard response.statusCode == OK_200 else {
			throw RemoteNewsReader.Error.invalidData
		}

		do {
			let jsonDecoder = JSONDecoder()
			jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
			let response = try jsonDecoder.decode(Response.self, from: data)

			return response.news
		} catch {
			print(error)
			throw RemoteNewsReader.Error.invalidData
		}
	}

}

//
//  NewsItem.swift
//  NewsReader
//
//  Created by Soheil on 04/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public struct NewsItem: Equatable {
	public let id: UUID
	public let source: Source
	public let tags: [Tag]?
	public let author: String
	public let title: String
	public let description: String
	public let urlToImage: URL?
//	public let publishedAt: Date
	public let content: String

	public init(id: UUID,
				source: Source,
				tags: [Tag]?,
				author: String,
				title: String,
				description: String,
				urlToImage: URL?,
//				publishedAt: Date,
				content: String) {

		self.id = id
		self.source = source
		self.tags = tags
		self.author = author
		self.title = title
		self.description = description
		self.urlToImage = urlToImage
//		self.publishedAt = publishedAt
		self.content = content
	}
}

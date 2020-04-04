//
//  NewsStore.swift
//  NewsReader
//
//  Created by Soheil on 04/04/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public protocol NewsStore {
	typealias DeletionCompletion = (Error?) -> Void
	typealias InsertionCompletion = (Error?) -> Void

	func deleteCachedNews(completion: @escaping DeletionCompletion)
	func insert(_ items: [LocalNewsItem], timestamp: Date, completion: @escaping InsertionCompletion)
}

public struct LocalNewsItem: Equatable {
	public let id: Int
	public let source: Source
	public let tags: [Tag]?
	public let author: String
	public let title: String
	public let description: String
	public let urlToImage: URL?
	public let content: String

	public init(id: Int,
				source: Source,
				tags: [Tag]?,
				author: String,
				title: String,
				description: String,
				urlToImage: URL?,
				content: String) {

		self.id = id
		self.source = source
		self.tags = tags
		self.author = author
		self.title = title
		self.description = description
		self.urlToImage = urlToImage
		self.content = content
	}
}

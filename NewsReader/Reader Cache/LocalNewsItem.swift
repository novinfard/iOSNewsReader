//
//  LocalNewsItem.swift
//  NewsReader
//
//  Created by Soheil on 05/04/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public struct LocalNewsItem: Equatable {
	public let id: Int
	public let source: LocalSourceItem
	public let tags: [LocalTagItem]?
	public let author: String
	public let title: String
	public let description: String
	public let urlToImage: URL?
	public let content: String

	public init(id: Int,
				source: LocalSourceItem,
				tags: [LocalTagItem]?,
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

public struct LocalSourceItem: Equatable {
	public let id: Int?
	public let name: String

	public init(id: Int?, name: String) {
		self.id = id
		self.name = name
	}
}

public struct LocalTagItem: Equatable {
	public let id: Int
	public let name: String

	public init(id: Int, name: String) {
		self.id = id
		self.name = name
	}
}

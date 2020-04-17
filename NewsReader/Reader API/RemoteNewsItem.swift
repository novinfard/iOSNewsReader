//
//  RemoteNewsItem.swift
//  NewsReader
//
//  Created by Soheil on 05/04/2020.
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

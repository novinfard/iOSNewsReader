//
//  NewsItem.swift
//  NewsReader
//
//  Created by Soheil on 04/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

struct NewsItem {
	let id: UUID
	let source: Source
	let tags: [Tag]?
	let author: String
	let title: String
	let description: String
	let urlToImage: URL?
	let publishedAt: Date
	let content: String
}

//
//  Response.swift
//  NewsReader
//
//  Created by Soheil on 04/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public struct Response: Decodable, Equatable {
	let status: String
	let totalResults: Int
	let news: [NewsItem]

	public init(status: String,
				totalResults: Int,
				news: [NewsItem]) {

		self.status = status
		self.totalResults = totalResults
		self.news = news
	}
}

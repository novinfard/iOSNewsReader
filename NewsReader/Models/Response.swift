//
//  Response.swift
//  NewsReader
//
//  Created by Soheil on 04/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

struct Response {
	let status: String
	let totalResults: Int
	let news: [NewsItem]
}

//
//  NewsReader.swift
//  NewsReader
//
//  Created by Soheil on 04/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

enum NewsReaderResult {
	case success([NewsItem])
	case error(Error)
}

protocol NewsReader {
	func load(completion: @escaping (NewsReaderResult) -> Void)
}

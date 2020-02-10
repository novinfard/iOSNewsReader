//
//  NewsReader.swift
//  NewsReader
//
//  Created by Soheil on 04/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public enum NewsReaderResult<Error: Swift.Error> {
	case success([NewsItem])
	case failure(Error)
}

protocol NewsReader {
	associatedtype Error: Swift.Error
	func load(completion: @escaping (NewsReaderResult<Error>) -> Void)
}

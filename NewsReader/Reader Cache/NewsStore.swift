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
	typealias RetrievalCompletion = (Error?) -> Void

	func deleteCachedNews(completion: @escaping DeletionCompletion)
	func insert(_ items: [LocalNewsItem], timestamp: Date, completion: @escaping InsertionCompletion)
	func retrieve(completion: @escaping RetrievalCompletion)
}

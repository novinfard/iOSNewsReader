//
//  NewsStore.swift
//  NewsReader
//
//  Created by Soheil on 04/04/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public enum RetrievedCachedNewsResult {
	case empty
	case found(items: [LocalNewsItem], timestamp: Date)
	case failure(Error)
}

public protocol NewsStore {
	typealias DeletionCompletion = (Error?) -> Void
	typealias InsertionCompletion = (Error?) -> Void
	typealias RetrievalCompletion = (RetrievedCachedNewsResult) -> Void

	/// The completion handler can be invoked in any thread.
 	/// Clients are responsible to dispatch to appropriate threads, if needed.
	func deleteCachedNews(completion: @escaping DeletionCompletion)

	/// The completion handler can be invoked in any thread.
 	/// Clients are responsible to dispatch to appropriate threads, if needed.
	func insert(_ items: [LocalNewsItem], timestamp: Date, completion: @escaping InsertionCompletion)

	/// The completion handler can be invoked in any thread.
 	/// Clients are responsible to dispatch to appropriate threads, if needed.
	func retrieve(completion: @escaping RetrievalCompletion)
}

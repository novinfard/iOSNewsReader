//
//  NewsStoreSpy.swift
//  NewsReaderTests
//
//  Created by Soheil on 07/04/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import NewsReader

class NewsStoreSpy: NewsStore {

	enum ReceivedMessage: Equatable {
		case deleteCachedNews
		case insert([LocalNewsItem], Date)
		case retrieve
	}

	private(set) var receivedMessages = [ReceivedMessage]()

	private var deletionCompletions = [DeletionCompletion]()
	private var insertionCompletions = [InsertionCompletion]()
	private var retrievalCompletions = [RetrievalCompletion]()

	func deleteCachedNews(completion: @escaping DeletionCompletion) {
		deletionCompletions.append(completion)
		receivedMessages.append(.deleteCachedNews)
	}

	func completeDeletion(with error: Error, at index: Int = 0) {
		deletionCompletions[index](error)
	}

	func completeDeletionSuccessfully(at index: Int = 0) {
		deletionCompletions[index](nil)
	}

	func insert(_ items: [LocalNewsItem], timestamp: Date, completion: @escaping InsertionCompletion) {
		insertionCompletions.append(completion)
		receivedMessages.append(.insert(items, timestamp))
	}

	func completeInsertion(with error: Error, at index: Int = 0) {
		insertionCompletions[index](error)
	}

	func completeInsertionSuccessfully(at index: Int = 0) {
		insertionCompletions[index](nil)
	}

	func retrieve(completion: @escaping RetrievalCompletion) {
		retrievalCompletions.append(completion)
		receivedMessages.append(.retrieve)
	}

	func completeRetrieval(with error: Error, at index: Int = 0) {
		retrievalCompletions[index](error)
	}

	func completeRetrievalWithEmptyCache(at index: Int = 0) {
		retrievalCompletions[index](nil)
	}

}

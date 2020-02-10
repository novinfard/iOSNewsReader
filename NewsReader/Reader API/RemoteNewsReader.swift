//
//  RemoteNewsReader.swift
//  NewsReader
//
//  Created by Soheil on 06/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public final class RemoteNewsReader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public typealias Result = NewsReaderResult<Error>

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (Result) -> Void) {
		client.get(from: url, completion: { [weak self] result in
			guard self != nil else { return }
			switch result {
			case let .success(data, response):
				completion(NewsItemsMapper.map(data, from: response))
			case .failure:
				completion(.failure(.connectivity))
			}
		})
	}
}

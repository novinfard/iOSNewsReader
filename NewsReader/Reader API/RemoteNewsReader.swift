//
//  RemoteNewsReader.swift
//  NewsReader
//
//  Created by Soheil on 06/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public enum HTTPClientResult {
	case success(HTTPURLResponse)
	case failure(Error)
}

public protocol HTTPClient {
	func get(
		from url: URL,
		completion: @escaping (HTTPClientResult) -> Void
	)
}

public final class RemoteNewsReader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (Error) -> Void) {
		client.get(from: url, completion: { result in
			switch result {
			case .success:
				completion(.invalidData)
			case .failure:
				completion(.connectivity)
			}
		})
	}

}

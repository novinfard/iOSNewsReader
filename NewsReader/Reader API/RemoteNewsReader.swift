//
//  RemoteNewsReader.swift
//  NewsReader
//
//  Created by Soheil on 06/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public protocol HTTPClient {
	func get(
		from url: URL,
		completion: @escaping  (Error) -> Void
	)
}

public final class RemoteNewsReader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (Error) -> Void = { _ in }) {
		client.get(from: url, completion: { error in
			completion(.connectivity)
		})
	}

}

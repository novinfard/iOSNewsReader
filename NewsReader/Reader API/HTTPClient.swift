//
//  HTTPClient.swift
//  NewsReader
//
//  Created by Soheil on 09/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public enum HTTPClientResult {
	case success(Data, HTTPURLResponse)
	case failure(Error)
}

public protocol HTTPClient {
	func get(
		from url: URL,
		completion: @escaping (HTTPClientResult) -> Void
	)
}

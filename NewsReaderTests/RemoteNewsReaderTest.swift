//
//  RemoteNewsReaderTest.swift
//  NewsReaderTests
//
//  Created by Soheil on 06/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest

class RemoteNewsReader {

}

class HTTPClient {
	var requestedUrl: URL?
}

class RemoteNewsReaderTest: XCTestCase {

	func test_init_doesNotRequestData() {
		let client = HTTPClient()
		_ = RemoteNewsReader()

		XCTAssertNil(
			client.requestedUrl,
			"When we don't request the data, the url of our HTTP client should be nil"
		)
	}

}

//
//  NewsReaderAPIEndToEndTests.swift
//  NewsReaderAPIEndToEndTests
//
//  Created by Soheil on 15/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest
import NewsReader

class NewsReaderAPIEndToEndTests: XCTestCase {
	func test_endToEndServerGetReaderResult_byTestAccountData() {
		let receivedResult = self.getNewsReaderResult()

		switch receivedResult {
		case .success(let items):
			XCTAssertEqual(items.count, 10, "Expected 10 items in news test account")

			XCTAssertEqual(items[0], expectedItem(at: 0))
		case .failure(let error):
			XCTFail("Expected successful news result, instead got \(error)")
		default:
			XCTFail("Expected successful news result, instead got no result")
		}
	}
}

// MARK: - Helpers
extension NewsReaderAPIEndToEndTests {
	private func getNewsReaderResult(file: StaticString = #file, line: UInt = #line) -> NewsReaderResult? {
		let testServerUrl = URL(string: "https://raw.githubusercontent.com/novinfard/iOSNewsReader/master/news.json")!
		let client = URLSessionHTTPClient()
		let loader = RemoteNewsReader(url: testServerUrl, client: client)

		trackMemoryLeak(client, file: file, line: line)
		trackMemoryLeak(loader, file: file, line: line)

		let exp = expectation(description: "Wait for load completion")

		var receivedResult: NewsReaderResult?
		loader.load { result in
			receivedResult = result
			exp.fulfill()
		}

		wait(for: [exp], timeout: 10)
		return receivedResult
	}

	private func expectedItem(at index: Int) -> NewsItem {
		return [
			NewsItem(
				id: 11,
				source: Source(id: nil, name: "Seekingalpha.com"),
				tags: nil,
				author: "Dean Popplewell",
				title: "The Week Ahead - Virus Saga Continues, Iowa Caucuses Are Here, RBA To Deliver Dovish Hold, And U.S. NFP To See Slight Rebound",
				description: "The primary driver for financial markets remains the coronavirus and its potential impact on the global economy.In addition to all the incremental virus updates, it will be an extremely busy week with rate decisions, voters in Iowa hit the polls in the first …",
				urlToImage: URL(string: "https://static3.seekingalpha.com/assets/og_image_192-59bfd51c9fe6af025b2f9f96c807e46f8e2f06c5ae787b15bf1423e6c676d4db.png"),
				content: "By Ed Moya\r\nThe primary driver for financial markets remains the coronavirus and its potential impact on the global economy. It is still too early to forecast the peak of the virus or even the impact it will have on the Chinese economy. The virus was spreadin… [+12235 chars]"
			),
		][index]
	}

}

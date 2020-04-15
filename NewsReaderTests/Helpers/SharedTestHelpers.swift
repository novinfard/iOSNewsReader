//
//  SharedTestHelpers.swift
//  NewsReaderTests
//
//  Created by Soheil on 15/04/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

func anyNSError() -> NSError {
	return NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
	return URL(string: "https://a-url.com")!
}

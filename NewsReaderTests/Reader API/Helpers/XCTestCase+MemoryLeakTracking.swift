//
//  XCTestCase+MemoryLeakTracking.swift
//  NewsReaderTests
//
//  Created by Soheil on 11/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import XCTest

extension XCTestCase {
	func trackMemoryLeak(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should be deallocated - potential retain cycle", file: file, line: line)
		}
	}
}

//
//  NewsCachePolicy.swift
//  NewsReader
//
//  Created by Soheil on 17/04/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

internal final class NewsCachePolicy {
	private init() {}

	private static let calendar = Calendar(identifier: .gregorian)
	private static let maxCacheAgeInDays = 7

	internal static func validate(_ timestamp: Date, against date: Date) -> Bool {
 		guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
			return false
		}
		return date < maxCacheAge
	}
}

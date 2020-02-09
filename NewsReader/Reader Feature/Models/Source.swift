//
//  Source.swift
//  NewsReader
//
//  Created by Soheil on 04/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public struct Source: Equatable {
	public let id: UUID?
	public let name: String

	public init(id: UUID?, name: String) {
		self.id = id
		self.name = name
	}
}

extension Source: Decodable {}

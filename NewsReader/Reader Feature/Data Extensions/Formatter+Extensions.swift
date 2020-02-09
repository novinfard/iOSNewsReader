//
//  Formatter+Extensions.swift
//  NewsReader
//
//  Created by Soheil on 09/02/2020.
//  Copyright © 2020 Novinfard. All rights reserved.
//

import Foundation

public extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}

public extension Date {
	var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}

public extension Numeric {
    var data: Data {
        var source = self
        return .init(bytes: &source, count: MemoryLayout<Self>.size)
    }

	init<D: DataProtocol>(_ data: D) {
        var value: Self = .zero
        let size = withUnsafeMutableBytes(of: &value, { data.copyBytes(to: $0)} )
        assert(size == MemoryLayout.size(ofValue: value))
        self = value
    }
}

public extension UInt64 {
    var bitPattern: Double { .init(bitPattern: self) }
}

public extension Date {
    var data: Data { timeIntervalSinceReferenceDate.bitPattern.littleEndian.data }
    init<D: DataProtocol>(data: D) {
        self.init(timeIntervalSinceReferenceDate: data.timeIntervalSinceReferenceDate)
    }
}

public extension DataProtocol {
    func value<N: Numeric>() -> N { .init(self) }
    var uint64: UInt64 { value() }
    var timeIntervalSinceReferenceDate: TimeInterval { uint64.littleEndian.bitPattern }
    var date: Date { .init(data: self) }
}

public extension JSONDecoder.DateDecodingStrategy {
    static let iso8601withFractionalSeconds = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)
        guard let date = Formatter.iso8601.date(from: string) else {
            throw DecodingError.dataCorruptedError(in: container,
                  debugDescription: "Invalid date: " + string)
        }
        return date
    }
}


public extension JSONEncoder.DateEncodingStrategy {
    static let iso8601withFractionalSeconds = custom {
        var container = $1.singleValueContainer()
        try container.encode(Formatter.iso8601.string(from: $0))
    }
}

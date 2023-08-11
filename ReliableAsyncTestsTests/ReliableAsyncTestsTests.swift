//
//  ReliableAsyncTestsTests.swift
//  ReliableAsyncTestsTests
//
//  Created by Oluwatobi Omotayo on 11/08/2023.
//

import XCTest

final class ReliableAsyncTestsTests: XCTestCase {
	
	func testBasics() async throws {
		let start = Date()
		try await Task.sleep(for: .seconds(1))
		let end = Date()
		XCTAssertEqual(end.timeIntervalSince(start), 1, accuracy: 0.1)
	}
	
	@MainActor
	func testTaskStart() async {
		// values: [Int] = []
		let values = LockIsolated([Int]())
		let task = Task {
			// values.append(1)
			values.withValue { $0.append(1) }
		}
		// values.append(2)
		values.withValue { $0.append(2) }
		await task.value
		XCTAssertEqual(values.value, [2, 1])
	}
}

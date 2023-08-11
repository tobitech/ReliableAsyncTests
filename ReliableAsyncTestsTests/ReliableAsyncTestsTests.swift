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
	
	@MainActor
	func testTaskStartOrder() async {
		let values = LockIsolated<[Int]>([])
		let task1 = Task { values.withValue { $0.append(1) } }
		let task2 = Task { values.withValue { $0.append(2) } }
		_ = await (task1.value, task2.value)
		XCTAssertEqual(values.value, [1, 2 ])
	}
	
	func testTaskGroupStartOrder() async {
		let values = await withTaskGroup(of: [Int].self) { group in
			group.addTask { [1] }
			group.addTask { [2] }
			return await group.reduce(into: [], +=)
		}
		XCTAssertEqual(values, [1, 2])
	}
}

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
	
	func testTaskStart() async {
		let task = Task {
			print(#line, { Thread.current }())
		}
		print(#line, { Thread.current }())
		await task.value
	}
}

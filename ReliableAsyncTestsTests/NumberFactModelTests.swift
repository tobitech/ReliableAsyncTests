import XCTest
@testable import ReliableAsyncTests

@MainActor
final class NumberFactModelTests: XCTestCase {
	func testIncrementDecrement() {
		let model = NumberFactModel()
		model.incrementButtonTapped()
		XCTAssertEqual(model.count, 1)
		model.decrementButtonTapped()
		XCTAssertEqual(model.count, 0)
	}
}

import Dependencies
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
	
	func testGetFact() async {
		let model = withDependencies {
			$0.numberFact.fact = { "\($0) is a good number." }
		} operation: {
			NumberFactModel()
		}

		await model.getFactButtonTapped()
		XCTAssertEqual(model.fact, "0 is a good number.")
		
		model.incrementButtonTapped()
		XCTAssertEqual(model.fact, nil)
		
		await model.getFactButtonTapped()
		XCTAssertEqual(model.fact, "1 is a good number")
	}
	
	func testFactClearsOut() async {
		// var factContinuation: AsyncStream<String>.Continuation!
		// let factStream = AsyncStream<String> { continuation in factContinuation = continuation }
		
		// we can relace the two lines above with some helpers in the Dependencies package:
		// this will be provided out of the box in Swift 5.9 rather than depending on the package.
		let fact = AsyncStream.makeStream(of: String.self)
		
		let model = withDependencies {
			// $0.numberFact.fact = { "\($0) is a good number." }
			// ignore the number that is handed to us and now defer all that to the async stream
			$0.numberFact.fact = { _ in
				// as soon as the stream emits something that is what will be returned from the fact.
				await fact.stream.first(where: { _ in true })!
			}
		} operation: {
			NumberFactModel()
		}
		
		model.fact = "An old fact about 0"

		let task = Task { await model.getFactButtonTapped() }
		await Task.yield()
		XCTAssertEqual(model.fact, nil) // ❌ testFactClearsOut(): XCTAssertEqual failed: ("Optional("An old fact about 0")") is not equal to ("nil")
		fact.continuation.yield("0 is a good number.")
		await task.value
		XCTAssertEqual(model.fact, "0 is a good number.")
	}
	
	func testFactIsLoading() async {
		let fact = AsyncStream.makeStream(of: String.self)
		
		let model = withDependencies {
			$0.numberFact.fact = { _ in
				await fact.stream.first(where: { _ in true })!
			}
		} operation: {
			NumberFactModel()
		}
		
		model.fact = "An old fact about 0"

		let task = Task { await model.getFactButtonTapped() }
		await Task.yield()
		XCTAssertEqual(model.isLoading, true) // ❌ testFactIsLoading(): XCTAssertEqual failed: ("false") is not equal to ("true")
		fact.continuation.yield("0 is a good number.")
		await task.value
		XCTAssertEqual(model.isLoading, false)
	}
}

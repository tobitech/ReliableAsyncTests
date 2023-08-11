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
	
	func testBackToBackGetFact()async throws {
		let fact0 = AsyncStream.makeStream(of: String.self)
		let fact1 = AsyncStream.makeStream(of: String.self)
		let callCount = LockIsolated(0)
		
		let model = withDependencies {
			$0.numberFact.fact = { number in
				callCount.withValue { $0 += 1 }
				if callCount.value == 1 {
					return await fact0.stream
					.first(where: { _ in true }) ?? ""} else if callCount.value == 2 {
						return await fact1.stream
						.first(where: { _ in true }) ?? ""} else {
							fatalError()
						}
			}
		} operation: {
			NumberFactModel()
		}
		
		let task0 = Task { await model.getFactButtonTapped() }
		let task1 = Task { await model.getFactButtonTapped() }
		await Task.yield()
		await Task.yield()
		await Task.yield()
		await Task.yield()
		await Task.yield()
		await Task.yield()
		fact1.continuation.yield("0 is a great number.")
		try await Task.sleep(for: .milliseconds(100))
		fact0.continuation.yield("0 is a better number.")
		await task0.value
		await task1.value
		XCTAssertEqual(model.fact, "0 is a great number.")
	}
	
	func testCancel() async {
		// if we ever try to await this factStream it would suspend forever.
		// let factStream = AsyncStream<Never> { _ in }
		
		// this pattern of suspending tasks forever is very useful in unit testing:
//		let model = withDependencies {
//			$0.numberFact.fact = { number in
//				for await _ in factStream { }
//				throw CancellationError()
//			}
//		} operation: {
//			NumberFactModel()
//		}
		
		let model = withDependencies {
			// we can rewrite all of the above (i.e. suspending a task forever)
			// using a helper from Dependencies package.
			$0.numberFact.fact = { _ in try await Task.never() }
		} operation: {
			NumberFactModel()
		}
		
		let task = Task { await model.getFactButtonTapped() }
		// await Task.yield() // seem we might need many yields
		// let's move this into an extension
//		for _ in 1...20 {
//			await Task.detached(priority: .background) {
//				await Task.yield()
//			}
//			.value
//		}
		await Task.megaYield()
		model.cancelButtonTapped()
		await task.value // allow the task to finish.
		XCTAssertEqual(model.fact, nil)
	}
}

extension Task where Success == Never, Failure == Never {
	static func megaYield() async {
		for _ in 1...20 {
			await Task<Void, Never>
				.detached(priority: .background) {
					await Task.yield()
				}
				.value
		}
	}
}

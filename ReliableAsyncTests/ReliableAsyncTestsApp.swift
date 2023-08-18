import SwiftUI

@main
struct ReliableAsyncTestsApp: App {
	var body: some Scene {
		WindowGroup {
			if NSClassFromString("XCTestCase") == nil { // makes sure that this doesn't run in XCTests
				ContentView(model: NumberFactModel())
			}
		}
	}
}

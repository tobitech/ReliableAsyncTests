import SwiftUI

@main
struct ReliableAsyncTestsApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView(model: NumberFactModel())
		}
	}
}

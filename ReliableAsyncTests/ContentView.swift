import SwiftUI

@MainActor
class NumberFactModel: ObservableObject {
	@Published var count = 0
	
	func incrementButtonTapped() {
		self.count += 1
	}
	func decrementButtonTapped() {
		self.count -= 1
	}
}

struct ContentView: View {
	@ObservedObject var model: NumberFactModel
	
	var body:some View {
		Form {
			Section {
				HStack {
					Button("-") {
						self.model.decrementButtonTapped()
					}
					Text( "\(self.model.count)")
					Button("+") {
						self.model.incrementButtonTapped()
					}
				}
			}
			.buttonStyle(.plain)
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(model: NumberFactModel())
	}
}

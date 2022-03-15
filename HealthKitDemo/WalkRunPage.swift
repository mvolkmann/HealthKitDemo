import SwiftUI

struct WalkRunPage: View {
    var data: [Steps];
    var body: some View {
        NavigationView {
            List(data.reversed(), id: \.id) { steps in
                HStack {
                    Text(steps.date, style: .date)
                    Spacer()
                    Text("\(steps.count) steps")
                }
            }.navigationTitle("Step Data")
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

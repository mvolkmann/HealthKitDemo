import SwiftUI

struct WalkRunPage: View {
    var data: [Steps];
    var body: some View {
        NavigationView {
            List(data.reversed(), id: \.id) { steps in
                VStack(alignment: .leading) {
                    Text("\(steps.count) steps")
                    Text(steps.date, style: .date).opacity(0.5)
                }
            }.navigationTitle("Step Data")
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

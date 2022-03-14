import SwiftUI

struct CyclingPage: View {
    var data: [Cycling];
    var body: some View {
        NavigationView {
            List(data.reversed(), id: \.id) { cycling in
                VStack(alignment: .leading) {
                    Text(String(format: "%.1f miles", cycling.distance))
                    Text(cycling.date, style: .date).opacity(0.5)
                }
            }.navigationTitle("Cycling Data")
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

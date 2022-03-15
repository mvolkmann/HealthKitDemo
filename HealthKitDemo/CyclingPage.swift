import SwiftUI

struct CyclingPage: View {
    var data: [Cycling];
    var body: some View {
        NavigationView {
            List(data.reversed(), id: \.id) { cycling in
                HStack {
                    Text(cycling.date, style: .date)
                    Spacer()
                    Text(String(format: "%.1f miles", cycling.distance))
                }
            }.navigationTitle("Cycling Data")
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

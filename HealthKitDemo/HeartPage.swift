import SwiftUI

struct HeartPage: View {
    var data: [HeartRate];
    var body: some View {
        NavigationView {
            List(data.reversed(), id: \.id) { heartRate in
                VStack(alignment: .leading) {
                    Text(String(format: "%.0f bpm", heartRate.bpm))
                    Text(heartRate.date, style: .date).opacity(0.5)
                }
            }.navigationTitle("Heart Data")
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

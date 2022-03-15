import SwiftUI

struct HeartPage: View {
    var data: [HeartRate];
    var body: some View {
        NavigationView {
            List(data.reversed(), id: \.id) { heartRate in
                HStack {
                    Text(heartRate.date, style: .date)
                    Spacer()
                    Text(String(format: "%.0f bpm", heartRate.bpm))
                }
            }.navigationTitle("Heart Data")
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

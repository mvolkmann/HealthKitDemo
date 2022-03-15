import HealthKit
import SwiftUI

struct HeartPage: View {
    @State private var data = [HeartRate]()
    
    private func loadData() async {
        data.removeAll()
        do {
            let store = try HealthStore()
            let collection = await store.queryHeart()
            if let collection = collection {
                for statistic in collection.statistics() {
                    var bpm = 0.0
                    if let quantity = statistic.averageQuantity() {
                        bpm = quantity.doubleValue(
                            for: HKUnit.count().unitDivided(by: HKUnit.minute())
                        )
                    }
                    let heartRate = HeartRate(bpm: bpm, date: statistic.startDate)
                    data.append(heartRate)
                }
            }
        } catch {
            print("HeartPage.loadData: error = \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            List(data.reversed(), id: \.id) { heartRate in
                HStack {
                    Text(heartRate.date, style: .date)
                    Spacer()
                    Text(String(format: "%.0f bpm", heartRate.bpm))
                }
            }
                .navigationTitle("Heart Data")
                .task { await loadData() }
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

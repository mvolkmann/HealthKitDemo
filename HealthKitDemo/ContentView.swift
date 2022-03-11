import HealthKit
import SwiftUI

struct ContentView: View {
    private var store: HealthStore?
    @State private var heartData = [HeartRate]()
    @State private var stepData = [Steps]()
    
    init() {
        store = HealthStore()
    }
    
    private func updateHeartData(_ collection: HKStatisticsCollection) {
        for statistic in collection.statistics() {
            var bpm = 0.0
            if let quantity = statistic.averageQuantity() {
                bpm = quantity.doubleValue(
                    for: HKUnit.count().unitDivided(by: HKUnit.minute())
                )
            }
            let heartRate = HeartRate(bpm: bpm, date: statistic.startDate)
            heartData.append(heartRate)
        }
    }
    
    private func updateStepData(_ collection: HKStatisticsCollection) {
        for statistic in collection.statistics() {
            let count = statistic.sumQuantity()?.doubleValue(for: .count())
            let step = Steps(count: Int(count ?? 0), date: statistic.startDate)
            stepData.append(step)
        }
    }
    
    var body: some View {
        NavigationView {
            List(stepData, id: \.id) { steps in
                VStack(alignment: .leading) {
                    Text("\(steps.count)")
                    Text(steps.date, style: .date).opacity(0.5)
                }
            }.navigationTitle("HealthKit Demo")
            /*
            List(heartData, id: \.id) { heartRate in
                VStack(alignment: .leading) {
                    Text(String(format: "%.1f", heartRate.bpm))
                    Text(heartRate.date, style: .date).opacity(0.5)
                }
            }.navigationTitle("HealthKit Demo")
            */
        }
            .navigationViewStyle(.stack) //TODO: Why needed?
            .onAppear {
                guard let store = store else { return }
                store.requestAuthorization { success in
                    if success {
                        store.queryHeart { collection in
                            if let collection = collection {
                               updateHeartData(collection)
                            }
                        }
                        store.querySteps { collection in
                            if let collection = collection {
                               updateStepData(collection)
                            }
                        }
                    }
                }
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

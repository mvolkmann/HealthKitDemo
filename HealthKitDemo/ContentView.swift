import HealthKit
import SwiftUI

struct ContentView: View {
    private var store: HealthStore?
    @State private var stepData = [Steps]()
    
    init() {
        store = HealthStore()
    }
    
    private func updateUI(_ collection: HKStatisticsCollection) {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()
        collection.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
            print("statistics = \(statistics)")
            let count = statistics.sumQuantity()?.doubleValue(for: .count())
            let step = Steps(count: Int(count ?? 0), date: statistics.startDate)
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
        }
            .onAppear {
                guard let store = store else { return }
                store.requestAuthorization { success in
                    if success {
                        store.querySteps { collection in
                            if let collection = collection {
                               updateUI(collection)
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

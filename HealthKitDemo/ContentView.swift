import HealthKit
import SwiftUI

struct ContentView: View {
    private var store: HealthStore?
    @State private var steps = [Step]()
    
    init() {
        store = HealthStore()
    }
    
    private func updateUI(_ collection: HKStatisticsCollection) {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()
        collection.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
            let count = statistics.sumQuantity()?.doubleValue(for: .count())
            let step = Step(count: Int(count ?? 0), date: statistics.startDate)
            steps.append(step)
        }
    }
    
    var body: some View {
        NavigationView {
            List(steps, id: \.id) { step in
                VStack(alignment: .leading) {
                    Text("\(step.count)")
                    Text(step.date, style: .date).opacity(0.5)
                }
            }.navigationTitle("HealthKit Demo")
        }
            .onAppear {
                if let store = store {
                    store.requestAuthorization { success in
                        if success {
                            store.calculateSteps { collection in
                                if let collection = collection {
                                   updateUI(collection)
                                }
                                
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

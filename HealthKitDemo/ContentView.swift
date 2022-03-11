import HealthKit
import SwiftUI

struct HeartPage: View {
    var heartData: [HeartRate];
    var body: some View {
        NavigationView {
            List(heartData, id: \.id) { heartRate in
                VStack(alignment: .leading) {
                    Text(String(format: "%.1f", heartRate.bpm))
                    Text(heartRate.date, style: .date).opacity(0.5)
                }
            }.navigationTitle("Heart Data")
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

struct WalkRunPage: View {
    var stepData: [Steps];
    var body: some View {
        NavigationView {
            List(stepData, id: \.id) { steps in
                VStack(alignment: .leading) {
                    Text("\(steps.count)")
                    Text(steps.date, style: .date).opacity(0.5)
                }
            }.navigationTitle("Step Data")
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

struct HealthTab: View {
    var kind: String

    var body: some View {
        Text("Information about \(kind) goes here.")
            .navigationBarTitle(kind)
    }
}

struct ContentView: View {
    @State private var heartData = [HeartRate]()
    @State private var stepData = [Steps]()
    
    private func getData() {
        let store = HealthStore()
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
        TabView {
            HealthTab(kind: "Characteristics").tabItem {
                Image(systemName: "info.circle.fill")
                Text("Characteristics")
            }
            HeartPage(heartData: heartData).tabItem {
                Image(systemName: "heart.fill")
                Text("Heart")
            }
            WalkRunPage(stepData: stepData).tabItem {
                Image(systemName: "figure.walk")
                Text("Walking/Running")
            }
            HealthTab(kind: "Cycling").tabItem {
                Image(systemName: "bicycle")
                Text("Cycling")
            }
        }
        .onAppear() {
            //UITabBar.appearance().backgroundColor = .systemGray5
            getData()
        }
        // Change color of Image and Text views which defaults to blue.
        //.accentColor(.purple)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

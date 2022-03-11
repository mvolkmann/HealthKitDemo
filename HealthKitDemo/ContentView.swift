import HealthKit
import SwiftUI

struct CyclingPage: View {
    var data: [Cycling];
    var body: some View {
        NavigationView {
            List(data, id: \.id) { cycling in
                VStack(alignment: .leading) {
                    Text(String(format: "%.1f miles", cycling.distance))
                    Text(cycling.date, style: .date).opacity(0.5)
                }
            }.navigationTitle("Cycling Data")
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

struct HeartPage: View {
    var data: [HeartRate];
    var body: some View {
        NavigationView {
            List(data, id: \.id) { heartRate in
                VStack(alignment: .leading) {
                    Text(String(format: "%.0f bpm", heartRate.bpm))
                    Text(heartRate.date, style: .date).opacity(0.5)
                }
            }.navigationTitle("Heart Data")
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

struct WalkRunPage: View {
    var data: [Steps];
    var body: some View {
        NavigationView {
            List(data, id: \.id) { steps in
                VStack(alignment: .leading) {
                    Text("\(steps.count) steps")
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
    @State private var cyclingData = [Cycling]()
    @State private var heartData = [HeartRate]()
    @State private var stepData = [Steps]()
    
    private func getData() {
        do {
            let store = try HealthStore()
            store.requestAuthorization { success in
                if success {
                    store.queryCharacteristics { characteristics in
                        switch characteristics.sex {
                        case HKBiologicalSex.female:
                            print("female")
                        case HKBiologicalSex.male:
                            print("male")
                        case HKBiologicalSex.other:
                            print("other")
                        case HKBiologicalSex.notSet:
                            print("not set")
                        @unknown default:
                            <#fatalError()#>
                        }
                    }
                    
                    store.queryCycling { collection in
                        if let collection = collection {
                           updateCyclingData(collection)
                        }
                    }
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
        } catch {
            print("error: \(error.localizedDescription)")
        }
    }
 
    private func updateCyclingData(_ collection: HKStatisticsCollection) {
        for statistic in collection.statistics() {
            let miles = statistic.sumQuantity()?.doubleValue(for: .mile())
            let cycling = Cycling(distance: Double(miles ?? 0), date: statistic.startDate)
            cyclingData.append(cycling)
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
            HeartPage(data: heartData).tabItem {
                Image(systemName: "heart.fill")
                Text("Heart")
            }
            WalkRunPage(data: stepData).tabItem {
                Image(systemName: "figure.walk")
                Text("Walking/Running")
            }
            CyclingPage(data: cyclingData).tabItem {
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

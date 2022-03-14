import HealthKit
import HealthKitUI
import SwiftUI

struct ContentView: View {
    @State private var activitySummaries: [HKActivitySummary]?
    @State private var characteristics: Characteristics?
    @State private var cyclingData = [Cycling]()
    @State private var heartData = [HeartRate]()
    @State private var stepData = [Steps]()
    
    private func getData() async throws {
        do {
            let store = try HealthStore()
            if try await store.requestAuthorization() {
                try await store.saveQuantity(
                    typeId: .bodyMass,
                    unit: .pound(),
                    value: 170
                )
                try await store.saveQuantity(
                    typeId: .waistCircumference,
                    unit: .inch(),
                    value: 33
                )
                    
                activitySummaries = await store.queryActivity()
                
                characteristics = await store.queryCharacteristics()
                
                var collection = await store.queryCycling()
                if let collection = collection {
                   updateCyclingData(collection)
                }
                
                collection = await store.queryHeart()
                if let collection = collection {
                   updateHeartData(collection)
                }
                
                collection = await store.queryRestingHeart()
                if let collection = collection {
                  updateRestingHeartData(collection)
                }
                
                collection = await store.querySteps()
                if let collection = collection {
                   updateStepData(collection)
                }
            }
        } catch {
            print("error: \(error)")
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
    
    private func updateRestingHeartData(_ collection: HKStatisticsCollection) {
        //print("collection.statistics() = \(collection.statistics())")
        for statistic in collection.statistics() {
            //print("statistic = \(statistic)")
            var bpm = 0.0
            if let quantity = statistic.averageQuantity() {
                bpm = quantity.doubleValue(
                    for: HKUnit.count().unitDivided(by: HKUnit.minute())
                )
                print("bpm = \(bpm)")
            }
            //let heartRate = HeartRate(bpm: bpm, date: statistic.startDate)
            //heartData.append(heartRate)
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
            CharacteristicsPage(data: characteristics).tabItem {
                Image(systemName: "info.circle.fill")
                Text("Characteristics")
            }
            ActivityPage(data: activitySummaries).tabItem {
                Image("Activity")
                Text("Activity")
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
            Task {
                do {
                    try await getData()
                } catch {
                    print("error getting data: \(error.localizedDescription)")
                }
            }
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

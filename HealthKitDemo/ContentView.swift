import HealthKit
import HealthKitUI
import SwiftUI

struct ContentView: View {
    private func getData() async throws {
        do {
            let store = try HealthStore()
            if try await store.requestAuthorization() {
                await store.saveQuantity(typeId: .bodyMass, unit: .pound(), value: 170)
                await store.saveQuantity(typeId: .waistCircumference, unit: .inch(), value: 33)
                    
                let collection = await store.queryRestingHeart()
                if let collection = collection {
                  updateRestingHeartData(collection)
                }
            }
        } catch {
            print("ContentView.getData: error = \(error)")
        }
    }
 
    private func updateRestingHeartData(_ collection: HKStatisticsCollection) {
        for statistic in collection.statistics() {
            var bpm = 0.0
            if let quantity = statistic.averageQuantity() {
                bpm = quantity.doubleValue(
                    for: HKUnit.count().unitDivided(by: HKUnit.minute())
                )
            }
            //let heartRate = HeartRate(bpm: bpm, date: statistic.startDate)
            //heartData.append(heartRate)
        }
    }
    
    var body: some View {
        TabView {
            CharacteristicsPage().tabItem {
                Image(systemName: "info.circle.fill")
                Text("Characteristics")
            }
            ActivityPage().tabItem {
                Image("Activity")
                Text("Activity")
            }
            HeartPage().tabItem {
                Image(systemName: "heart.fill")
                Text("Heart")
            }
            WalkRunPage().tabItem {
                Image(systemName: "figure.walk")
                Text("Walking/Running")
            }
            CyclingPage().tabItem {
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

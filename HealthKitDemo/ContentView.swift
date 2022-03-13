import HealthKit
import SwiftUI

struct CharacteristicsPage: View {
    var data: Characteristics?;
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if let data = data {
                    Text("Sex: \(data.sex)")
                    Text("Date of Birth: \(data.dateOfBirthFormatted)")
                    Text("Height: \(data.heightInImperial)")
                    Text("Waist: \(String(format: "%.1f inches", data.waistInInches))")
                }
            }.navigationTitle("Characteristics")
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

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

struct ContentView: View {
    @State private var characteristics: Characteristics?
    @State private var cyclingData = [Cycling]()
    @State private var heartData = [HeartRate]()
    @State private var stepData = [Steps]()
    
    private func getData() async throws {
        do {
            let store = try HealthStore()
            if try await store.requestAuthorization() {
                let appleStats = try await store.queryAppleStats()
                if let appleStats = appleStats {
                    print("appleStats = \(appleStats)")
                } else {
                    print("no appleStats")
                }
                
                characteristics = try await store.queryCharacteristics()
                
                var collection = try await store.queryCycling()
                if let collection = collection {
                   updateCyclingData(collection)
                }
                
                collection = try await store.queryHeart()
                if let collection = collection {
                   updateHeartData(collection)
                }
                
                collection = try await store.queryRestingHeart()
                if let collection = collection {
                  updateRestingHeartData(collection)
                }
                
                collection = try await store.querySteps()
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
        print("collection.statistics() = \(collection.statistics())")
        for statistic in collection.statistics() {
            print("statistic = \(statistic)")
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

import HealthKit
import HealthKitUI
import SwiftUI

struct ContentView: View {
    private func requestAuth() async throws {
        do {
            let store = try HealthStore()
            if try await store.requestAuthorization() {
                // This demonstrates writing to HealthKit.
                await store.saveQuantity(typeId: .bodyMass, unit: .pound(), value: 172)
                await store.saveQuantity(typeId: .waistCircumference, unit: .inch(), value: 34)
            } else {
                print("ContentView.requestAuth: failed")
            }
        } catch {
            print("ContentView.requestAuth: error = \(error)")
        }
    }
 
    var body: some View {
        if (HKHealthStore.isHealthDataAvailable()) {
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
                        try await requestAuth()
                    } catch {
                        print("ContentView onAppear: error \(error.localizedDescription)")
                    }
                }
            }
            // Change color of Image and Text views which defaults to blue.
            //.accentColor(.purple)
        } else {
           Text("HealthKit is not avaiable on this device.")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

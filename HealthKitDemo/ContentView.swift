import HealthKit
import HealthKitUI
import SwiftUI

enum HealthKitStatus {
    case unknown, authFailed, available, notAvailable
}

struct ContentView: View {
    @State private var status: HealthKitStatus = .unknown
    
    private func check() async {
        if (!HKHealthStore.isHealthDataAvailable()) {
            status = .notAvailable
        } else {
            do {
                try await requestAuth()
                status = .available
            } catch {
                status = .authFailed
            }
        }
    }
    
    private func requestAuth() async throws {
        let store = HealthStore()
        
        // The user will only be prompted if they
        // have not already granted or denied permission.
        try await store.requestAuthorization()
        
        // This demonstrates writing to HealthKit.
        await store.saveQuantity(typeId: .bodyMass, unit: .pound(), value: 172)
        await store.saveQuantity(typeId: .waistCircumference, unit: .inch(), value: 34)
    }
 
    var body: some View {
        VStack {
            switch status {
            case .available:
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
            case .unknown:
                ProgressView()
            case .authFailed:
               Text("Failed to request HealthKit authorization.")
            case .notAvailable:
               Text("HealthKit is not available on this device.")
            }
        }.task { await check() }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

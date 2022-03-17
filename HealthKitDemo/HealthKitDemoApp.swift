import SwiftUI

@main
struct HealthKitDemoApp: App {
    // This registers use of AppDelegate defined in AppDelegate.swift.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

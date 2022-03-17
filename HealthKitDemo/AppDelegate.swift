import SwiftUI
import UIKit

// This is registered in HealthKitDemoApp.swift.
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Change the appearance of the status and navigation bars.
        // This is not currently possible using only SwiftUI,
        // so we need to use the UIKit approach.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color("PrimaryColor"))
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
            //.font: UIFont.monospacedSystemFont(ofSize: 36, weight: .black)
        ]
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        return true
    }
}

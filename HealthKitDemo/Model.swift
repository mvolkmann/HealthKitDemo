import Foundation
import HealthKit

struct Characteristics {
    let sex: HKBiologicalSex
}

struct Cycling: Identifiable {
    let id = UUID()
    let distance: Double
    let date: Date
}

struct HeartRate: Identifiable {
    let id = UUID()
    let bpm: Double
    let date: Date
}

struct Steps: Identifiable {
    let id = UUID()
    let count: Int
    let date: Date
}

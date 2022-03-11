import Foundation
import HealthKit

struct Characteristics {
    let sexEnum: HKBiologicalSex
    var sex: String {
        switch sexEnum {
        case HKBiologicalSex.female:
            return "female"
        case HKBiologicalSex.male:
            return "male"
        case HKBiologicalSex.notSet:
            return "not set"
        default:
            return "other"
        }
    }
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

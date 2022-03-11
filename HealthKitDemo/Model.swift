import Foundation
import HealthKit

struct Characteristics {
    let dateOfBirth: Date?
    
    // Computed property
    var dateOfBirthFormatted: String {
        guard let dateOfBirth = dateOfBirth else { return "unknown" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: dateOfBirth)
    }
    
    let height: Double
    
    let sexEnum: HKBiologicalSex
    
    // Computed property
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

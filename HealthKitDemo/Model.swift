import Foundation
import HealthKit

struct Characteristics {
    let bodyMass: Double
    
    let dateOfBirth: Date?
    
    // Computed property
    var dateOfBirthFormatted: String {
        guard let dateOfBirth = dateOfBirth else { return "unknown" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: dateOfBirth)
    }
    
    let heartRate: Int
    
    let heightInMeters: Double
    var heightInImperial: String {
        let totalInches = heightInMeters * 39.3701;
        let feet = totalInches / 12;
        let inches = totalInches.truncatingRemainder(dividingBy: 12);
        return "\(Int(floor(feet)))' \(Int(inches.rounded()))\""
    }
    
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
    
    var waistInMeters: Double
    var waistInInches: Int {
        return Int((waistInMeters * 39.3701).rounded())
    }
}

struct Cycling: Identifiable {
    let id = UUID()
    let date: Date
    let distance: Double
}

struct Heart: Identifiable {
    let id = UUID()
    let date: Date
    let averageBpm: Double
    let restingBpm: Double
    let walkingBpm: Double
}

struct Steps: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

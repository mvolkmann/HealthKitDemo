import Foundation

struct HeartRate: Identifiable {
    let id = UUID()
    let bpm: Int
    let date: Date
}

struct Steps: Identifiable {
    let id = UUID()
    let count: Int
    let date: Date
}

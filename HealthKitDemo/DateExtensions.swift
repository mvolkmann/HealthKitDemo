import Foundation

extension Date {
    
    static func daysAgo(_ days: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(
            byAdding: .day,
            value: -days,
            to: Date()
        )!
    }
        
    static func mondayAt12AM() -> Date {
        return Calendar(identifier: .iso8601).date(from: Calendar(identifier: .iso8601).dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }
                
    
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }

    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }
}

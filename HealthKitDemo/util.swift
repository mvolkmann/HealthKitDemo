import HealthKit

func dToI(_ d: Double) -> Int {
    return Int(d + 0.5)
}

func quantityOnDate(_ statistics: [HKStatistics], on date: Date) -> Double {
    let statistic = statistics.first(
        where: {element in element.startDate <= date && date < element.endDate}
    )
    if let statistic = statistic, let value = statistic.averageQuantity() {
        return value.doubleValue(
            for: HKUnit.count().unitDivided(by: HKUnit.minute())
        )
    } else {
        return 0
    }
}

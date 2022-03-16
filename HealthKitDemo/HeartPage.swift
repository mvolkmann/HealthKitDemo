import HealthKit
import SwiftUI

private func quantityOnDate(_ statistics: [HKStatistics], on date: Date) -> Double {
    let statistic = statistics.first(
        where: {element in element.startDate <= date && date < element.endDate}
    )
    if let statistic = statistic, let quantity = statistic.averageQuantity() {
        return quantity.doubleValue(
            for: HKUnit.count().unitDivided(by: HKUnit.minute())
        )
    } else {
        return 0
    }
}

struct HeartPage: View {
    @State private var data = [Heart]()
    
    private func loadData() async {
        data.removeAll()
        let store = HealthStore()
        
        let heartData = await store.queryCollection(
            typeId: .heartRate,
            options: .discreteAverage
        )
        guard let heartData = heartData else {
            print("HeartPage.loadData: failed to get heartRate data")
            return
        }
                  
        let restingData = await store.queryCollection(
            typeId: .restingHeartRate,
            options: .discreteAverage
        )
        guard let restingData = restingData else {
            print("HeartPage.loadData: failed to get restingHeartRate data")
            return
        }
                  
        let walkingData = await store.queryCollection(
            typeId: .walkingHeartRateAverage,
            options: .discreteAverage
        )
        guard let walkingData = walkingData else {
            print("HeartPage.loadData: failed to get walkingHeartRateAverage data")
            return
        }
        
        let heartArr = heartData.statistics()
        let restingArr = restingData.statistics()
        let walkingArr = walkingData.statistics()
        
        for days in 0...6 {
            let date = Date.daysAgo(days)
            let averageBpm = quantityOnDate(heartArr, on: date)
            let restingBpm = quantityOnDate(restingArr, on: date)
            let walkingBpm = quantityOnDate(walkingArr, on: date)
            data.append(Heart(
                date: date,
                averageBpm: averageBpm,
                restingBpm: restingBpm,
                walkingBpm: walkingBpm
            ))
        }
    }
    
    var body: some View {
        NavigationView {
            List(data, id: \.id) { heart in
                VStack(alignment: .leading) {
                    Text(heart.date, style: .date).bold()
                    HStack {
                        Text("BPM:")
                        if heart.averageBpm > 0 {
                            Text("\(dToI(heart.averageBpm)) avg")
                        }
                        if heart.restingBpm > 0 {
                            Text("\(dToI(heart.restingBpm)) resting")
                        }
                        if heart.walkingBpm > 0 {
                            Text("\(dToI(heart.walkingBpm)) walking")
                        }
                    }
                }
            }
                .navigationTitle("Heart Data")
                .task { await loadData() }
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

import HealthKit
import SwiftUI

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
        let heartArr = heartData.statistics()
                  
        let restingData = await store.queryCollection(
            typeId: .restingHeartRate,
            options: .discreteAverage
        )
        guard let restingData = restingData else {
            print("HeartPage.loadData: failed to get restingHeartRate data")
            return
        }
        let restingArr = restingData.statistics()
                  
        let walkingData = await store.queryCollection(
            typeId: .walkingHeartRateAverage,
            options: .discreteAverage
        )
        guard let walkingData = walkingData else {
            print("HeartPage.loadData: failed to get walkingHeartRateAverage data")
            return
        }
        let walkingArr = walkingData.statistics()
        
        //TODO: Why can I get a single value for an unspecified date,
        //TODO: but queryCollection below returns 0.0 for every day in the range?
        let variability = await store.queryQuantity(typeId: .heartRateVariabilitySDNN)
        print("variability = \(variability!)")
        
        let variabilityData = await store.queryCollection(
            typeId: .heartRateVariabilitySDNN,
            //options: .discreteMax
            options: []
        )
        guard let variabilityData = variabilityData else {
            print("HeartPage.loadData: failed to get heartRateVariabilitySDNN data")
            return
        }
        let variabilityArr = variabilityData.statistics()
        /*
        for obj in variabilityArr {
            print("startDate = \(obj.startDate)")
            print("endDate = \(obj.endDate)")
        }
        */
        
        for days in 0...6 {
            let date = Date.daysAgo(days)
            let averageBpm = averagePerMinuteOnDate(heartArr, on: date)
            let restingBpm = averagePerMinuteOnDate(restingArr, on: date)
            let walkingBpm = averagePerMinuteOnDate(walkingArr, on: date)
            //TODO: Why is the variability for every day 0.0?
            let variability = averagePerMinuteOnDate(variabilityArr, on: date)
            print("variability = \(variability)")
            data.append(Heart(
                date: date,
                averageBpm: averageBpm,
                restingBpm: restingBpm,
                variability: variability,
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
                        if heart.variability > 0 {
                            Text("\(dToI(heart.variability)) var")
                        }
                    }
                }
            }
                .navigationBarTitle("Heart Data")
                .task { await loadData() }
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

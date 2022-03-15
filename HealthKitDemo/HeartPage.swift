import HealthKit
import SwiftUI

struct HeartPage: View {
    @State private var data = [Heart]()
    
    private func loadData() async {
        data.removeAll()
        do {
            let store = try HealthStore()
            let heartData = await store.queryHeart()
            let restingData = await store.queryRestingHeart()
            
            if let heartData = heartData, let restingData = restingData {
                let heartArr = heartData.statistics()
                let restingArr = restingData.statistics()
                
                for heart in heartArr {
                    var averageBpm = 0.0
                    if let quantity = heart.averageQuantity() {
                        averageBpm = quantity.doubleValue(
                            for: HKUnit.count().unitDivided(by: HKUnit.minute())
                        )
                    }
                    
                    let resting = restingArr.first(where: {element in
                        element.startDate == heart.startDate
                    })
                    var restingBpm = 0.0
                    if let resting = resting, let quantity = resting.averageQuantity() {
                        restingBpm = quantity.doubleValue(
                            for: HKUnit.count().unitDivided(by: HKUnit.minute())
                        )
                    }
                    
                    let heart = Heart(
                        date: heart.startDate,
                        averageBpm: averageBpm,
                        restingBpm: restingBpm
                    )
                    data.append(heart)
                }
            }
        } catch {
            print("HeartPage.loadData: error = \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            List(data.reversed(), id: \.id) { heart in
                VStack(alignment: .leading) {
                    Text(heart.date, style: .date).bold()
                    HStack {
                        Text("BPM:")
                        if heart.averageBpm > 0 {
                            Text(String(format: "%.0f avg", heart.averageBpm))
                        }
                        if heart.restingBpm > 0 {
                            Text(String(format: ", %.0f resting", heart.restingBpm))
                        }
                    }
                }
            }
                .navigationTitle("Heart Data")
                .task { await loadData() }
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

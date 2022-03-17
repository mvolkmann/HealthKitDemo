import SwiftUI
import HealthKit

struct WalkRunPage: View {
    @State private var data = [WalkRun]()
    
    private func loadData() async {
        data.removeAll()
        let store = HealthStore()
        
        let flightsClimbedCollection = await store.queryCollection(
            typeId: .flightsClimbed,
            options: .cumulativeSum
        )
        guard let flightsClimbedCollection = flightsClimbedCollection else {
            print("WalkRunPage.loadData: failed to get flightsClimbed data")
            return
        }
        let flightsClimbedArr = flightsClimbedCollection.statistics()
        
        //TODO: How can you query a category value over a date range?
        //TODO: See HealthStore.queryCategoryCollection which isn't working.
        //TODO: Note that you are already displaying STAND hours in ActivityPage!`
        /*
        let standHourCollection = await store.queryCategoryCollection(
            typeId: HKCategoryTypeIdentifier.appleStandHour,
            options: .cumulativeSum
        )
        guard let standHourCollection = standHourCollection else {
            print("WalkRunPage.loadData: failed to get appleStandHour data")
            return
        }
        let standHourArr = standHourCollection.statistics()
        */
        
        let standTimeCollection = await store.queryCollection(
            typeId: .appleStandTime,
            options: .cumulativeSum
        )
        guard let standTimeCollection = standTimeCollection else {
            print("WalkRunPage.loadData: failed to get appleStandTime data")
            return
        }
        let standTimeArr = standTimeCollection.statistics()
        
        let stepCountCollection = await store.queryCollection(
            typeId: .stepCount,
            options: .cumulativeSum
        )
        guard let stepCountCollection = stepCountCollection else {
            print("WalkRunPage.loadData: failed to get stepCount data")
            return
        }
        let stepCountArr = stepCountCollection.statistics()
        
        for days in 0...6 {
            let date = Date.daysAgo(days)
            let flightsClimbed = dToI(sumCountOnDate(flightsClimbedArr, on: date))
            //let standHours = sumOnDate(standHourArr, on: date)
            let standTime = dToI(minutesOnDate(standTimeArr, on: date))
            let stepCount = dToI(sumCountOnDate(stepCountArr, on: date))
            data.append(WalkRun(
                date: date,
                flightsClimbed: flightsClimbed,
                //standHours: standHours,
                standTime: standTime,
                stepCount: stepCount
            ))
        }
    }
    
    var body: some View {
        NavigationView {
            List(data, id: \.id) { walkRun in
                VStack(alignment: .leading) {
                    Text(walkRun.date, style: .date).bold()
                    Text("Flights Climbed: \(walkRun.flightsClimbed)")
                    //Text("Stand Hours: \(walkRun.standHours)")
                    Text("Stand Time: \(walkRun.standTime) minutes")
                    Text("Step Count: \(walkRun.stepCount)")
                }
            }
                .navigationBarTitle("Walking/Running Data")
                .task { await loadData() }
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

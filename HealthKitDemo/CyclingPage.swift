import SwiftUI

struct CyclingPage: View {
    @State private var data = [Cycling]()
    
    private func loadData() async {
        data.removeAll()
        
        let store = HealthStore()
        let collection = await store.queryCollection(
            typeId: .distanceCycling,
            options: .cumulativeSum
        )
        if let collection = collection {
            for statistic in collection.statistics() {
                let miles = statistic.sumQuantity()?.doubleValue(for: .mile())
                let cycling = Cycling(date: statistic.startDate, distance: Double(miles ?? 0))
                data.append(cycling)
            }
        }
    }
    
    private func loadWorkouts() async {
        do {
            let workouts = try await HealthStore().queryWorkouts()
            if let workouts = workouts {
                //TODO: Why isn't this getting any data?
                print("CyclingPage.loadWorkouts: count = \(workouts.count)")
                print("CyclingPage.loadWorkouts: workouts = \(workouts)")
            }
        } catch {
            print("CyclingPage.loadWorkouts: error \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        NavigationView {
            List(data.reversed(), id: \.id) { cycling in
                HStack {
                    Text(cycling.date, style: .date)
                    Spacer()
                    Text(String(format: "%.1f miles", cycling.distance))
                }
            }
            .navigationBarTitle("Cycling Data")
            .task {
                await loadData()
                await loadWorkouts()
            }
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

import SwiftUI

struct WalkRunPage: View {
    @State private var data = [Steps]()
    
    private func loadData() async {
        data.removeAll()
        let store = HealthStore()
        let collection = await store.querySteps()
        if let collection = collection {
            for statistic in collection.statistics() {
                let count = statistic.sumQuantity()?.doubleValue(for: .count())
                let step = Steps(date: statistic.startDate, count: Int(count ?? 0))
                data.append(step)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List(data.reversed(), id: \.id) { steps in
                HStack {
                    Text(steps.date, style: .date)
                    Spacer()
                    Text("\(steps.count) steps")
                }
            }
                .navigationTitle("Step Data")
                .task { await loadData() }
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

import SwiftUI

struct CyclingPage: View {
    @State private var data = [Cycling]()
    
    private func loadData() async {
        data.removeAll()
        do {
            let store = try HealthStore()
            let collection = await store.queryCycling()
            if let collection = collection {
                for statistic in collection.statistics() {
                    let miles = statistic.sumQuantity()?.doubleValue(for: .mile())
                    let cycling = Cycling(date: statistic.startDate, distance: Double(miles ?? 0))
                    data.append(cycling)
                }
            }
        } catch {
            print("CyclingPage.loadData: error = \(error)")
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
                .navigationTitle("Cycling Data")
                .task { await loadData() }
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}

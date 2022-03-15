import SwiftUI

struct CharacteristicsPage: View {
    @State private var data: Characteristics?
    
    private func loadData() async {
        do {
            let store = try HealthStore()
            data = await store.queryCharacteristics()
        } catch {
            print("CharacteristicsPage.loadData: error = \(error)")
        }
    }
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if let data = data {
                    Text("Sex: \(data.sex)")
                    Text("Date of Birth: \(data.dateOfBirthFormatted)")
                    Text("Height: \(data.heightInImperial)")
                    Text("Waist: \(data.waistInInches) inches")
                    Text("Weight: \(dToI(data.bodyMass)) pounds")
                    Text("Last Heart Rate: \(data.heartRate) bpm")
                }
            }
                .navigationTitle("Characteristics")
                .task { await loadData() }
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}


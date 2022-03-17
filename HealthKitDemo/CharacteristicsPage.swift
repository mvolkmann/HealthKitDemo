import SwiftUI

struct CharacteristicsPage: View {
    @State private var data: Characteristics?
    
    private func loadData() async {
        let store = HealthStore()
        data = await store.queryCharacteristics()
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
                .navigationBarTitle("Characteristics")
                .navigationBarItems(
                    leading: Button("Left") { print("pressed Left")}
                        .foregroundColor(.white),
                    trailing: Button("Right") { print("pressed Right")}
                        .foregroundColor(.white)
                )
                .task { await loadData() }
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}


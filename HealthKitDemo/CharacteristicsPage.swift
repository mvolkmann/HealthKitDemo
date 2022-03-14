import SwiftUI

struct CharacteristicsPage: View {
    var data: Characteristics?;
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
            }.navigationTitle("Characteristics")
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}


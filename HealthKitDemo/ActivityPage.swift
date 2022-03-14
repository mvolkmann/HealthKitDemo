import HealthKitUI
import SwiftUI

struct Rings: UIViewRepresentable {
    var activitySummary: HKActivitySummary

    func makeUIView(context: Context) -> HKActivityRingView {
        let ringView = HKActivityRingView()
        ringView.setActivitySummary(activitySummary, animated: true)
        return ringView
    }

    func updateUIView(_ uiView: HKActivityRingView, context: Context) {
        uiView.activitySummary = self.activitySummary
    }
}

struct Activity: View {
    let moveColor: UInt = 0xff376c;
    let exerciseColor: UInt = 0x9ef631;
    let standColor: UInt = 0x00f0db;
    
    var summary: HKActivitySummary
    
    var body: some View {
        let energyUnit   = HKUnit.kilocalorie()
        let standUnit    = HKUnit.count()
        let exerciseUnit = HKUnit.second()
        
        let energyGoal   = summary.activeEnergyBurnedGoal.doubleValue(for: energyUnit)
        let standGoal    = summary.appleStandHoursGoal.doubleValue(for: standUnit)
        let exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: exerciseUnit) / 60
        
        let energy   = summary.activeEnergyBurned.doubleValue(for: energyUnit)
        let stand    = summary.appleStandHours.doubleValue(for: standUnit)
        let exercise = summary.appleExerciseTime.doubleValue(for: exerciseUnit) / 60
        
        let energyPercent   = energyGoal == 0 ? 0 : energy / energyGoal * 100
        let standPercent    = standGoal == 0 ? 0 : stand / standGoal * 100
        let exercisePercent = exerciseGoal == 0 ? 0 : exercise / exerciseGoal * 100
        
        let date = summary.dateComponents(for: .current).date
        
        let size = 100.0
        return VStack(alignment: .leading) {
            if let date = date { Text(date, style: .date) }
            Rings(activitySummary: summary)
                .frame(minWidth: size, maxWidth: size, minHeight: size, maxHeight: size)
            Text("MOVE: \(dToI(energyPercent))% " +
                 "\(dToI(energy))/\(dToI(energyGoal)) calories")
                .foregroundColor(Color(hex: moveColor))
            Text("EXERCISE: \(dToI(exercisePercent))% " +
                 "\(dToI(exercise))/\(dToI(exerciseGoal)) minutes")
                .foregroundColor(Color(hex: exerciseColor))
            Text("STAND: \(dToI(standPercent))% " +
                 "\(dToI(stand))/\(dToI(standGoal)) hours")
                .foregroundColor(Color(hex: standColor))
        }.padding(.all, 10).background(.black).foregroundColor(.white)
    }
}

struct ActivityPage: View {
    var data: [HKActivitySummary]?;
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if let data = data {
                    List(data.reversed(), id: \.self) { activitySummary in
                        Activity(summary: activitySummary)
                    }
                } else {
                    Text("No activity data was found.")
                }
            }.navigationTitle("Activity")
        }.navigationViewStyle(.stack) //TODO: Why needed?
    }
}
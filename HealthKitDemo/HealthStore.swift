import Foundation
import HealthKit

class HealthStore {
    var query: HKStatisticsCollectionQuery?
    var store: HKHealthStore?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            store = HKHealthStore()
        } else {
            print("Health data is not available.")
        }
    }
    
    func calculateSteps(completion: @escaping (HKStatisticsCollection?) -> Void) {
        let stepCount = HKQuantityType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let anchorDate = Date.mondayAt12AM()
        let daily = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: Date(),
            options: .strictStartDate
        )
        query = HKStatisticsCollectionQuery(
            quantityType: stepCount,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: daily
        )
        query!.initialResultsHandler = { query, collection, error in
            completion(collection)
        }
        if let store = store, let query = query {
            store.execute(query)
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let store = self.store else { return completion(false) }
        
        let heartRate = HKQuantityType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let stepCount = HKQuantityType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        
        store.requestAuthorization(
            toShare: [],
            read: [heartRate, stepCount]) {
            (success, error) in completion(success)
        }
    }
}

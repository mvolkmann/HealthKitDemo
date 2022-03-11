import Foundation
import HealthKit

class HealthStore {
    var hkStore: HKHealthStore?
    
    init() throws {
        if HKHealthStore.isHealthDataAvailable() {
            hkStore = HKHealthStore()
        } else {
            throw RuntimeError("Health data is not available.")
        }
    }
    
    func query(
        type: HKQuantityType,
        options: HKStatisticsOptions,
        completion: @escaping (HKStatisticsCollection?) -> Void
    ) {
        let startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date())
        let anchorDate = Date.mondayAt12AM()
        let daily = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: Date(),
            options: .strictStartDate
        )
        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: options,
            anchorDate: anchorDate,
            intervalComponents: daily
        )
        query.initialResultsHandler = { query, collection, error in
            completion(collection)
        }
        if let store = hkStore {
            store.execute(query)
        }
    }
    
    func queryHeart(completion: @escaping (HKStatisticsCollection?) -> Void) {
        let heartRate = HKQuantityType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        query(type: heartRate, options: .discreteAverage, completion: completion)
    }
    
    func querySteps(completion: @escaping (HKStatisticsCollection?) -> Void) {
        let stepCount = HKQuantityType.quantityType(
            forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        query(type: stepCount, options: .cumulativeSum, completion: completion)
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let store = hkStore else { return completion(false) }
        
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

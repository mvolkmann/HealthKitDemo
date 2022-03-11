import Foundation
import HealthKit

class HealthStore {
    var hkStore: HKHealthStore?
    
    init() throws {
        if !HKHealthStore.isHealthDataAvailable() {
            throw RuntimeError("Health data is not available.")
        }
        hkStore = HKHealthStore()
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
        query.initialResultsHandler = { query, collection, error in completion(collection) }
        if let store = hkStore { store.execute(query) }
    }
    
    func queryCycling(completion: @escaping (HKStatisticsCollection?) -> Void) {
        let type = HKQuantityType.quantityType(forIdentifier: .distanceCycling)!
        query(type: type, options: .cumulativeSum, completion: completion)
    }
    
    func queryHeart(completion: @escaping (HKStatisticsCollection?) -> Void) {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        query(type: type, options: .discreteAverage, completion: completion)
    }
    
    func querySteps(completion: @escaping (HKStatisticsCollection?) -> Void) {
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        query(type: type, options: .cumulativeSum, completion: completion)
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let store = hkStore else { return completion(false) }
        
        let cycling = HKQuantityType.quantityType(forIdentifier: .distanceCycling)!
        let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        store.requestAuthorization(
            toShare: [],
            read: [cycling, heartRate, stepCount]) {
            (success, error) in completion(success)
        }
    }
}

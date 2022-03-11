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
    
    private func getType(_ typeId: HKQuantityTypeIdentifier) -> HKQuantityType {
        return HKQuantityType.quantityType(forIdentifier: typeId)!
    }
    
    func query(
        typeId: HKQuantityTypeIdentifier,
        options: HKStatisticsOptions,
        completion: @escaping (HKStatisticsCollection?) -> Void
    ) {
        guard let store = hkStore else { return }
        
        let startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date())
        let anchorDate = Date.mondayAt12AM()
        let daily = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: Date(),
            options: .strictStartDate
        )
        let q = HKStatisticsCollectionQuery(
            quantityType: getType(typeId),
            quantitySamplePredicate: predicate,
            options: options,
            anchorDate: anchorDate,
            intervalComponents: daily
        )
        q.initialResultsHandler = { query, collection, error in completion(collection) }
        store.execute(q)
    }
    
    func queryCycling(completion: @escaping (HKStatisticsCollection?) -> Void) {
        query(typeId: .distanceCycling, options: .cumulativeSum, completion: completion)
    }
    
    func queryHeart(completion: @escaping (HKStatisticsCollection?) -> Void) {
        query(typeId: .heartRate, options: .discreteAverage, completion: completion)
    }
    
    func querySteps(completion: @escaping (HKStatisticsCollection?) -> Void) {
        query(typeId: .stepCount, options: .cumulativeSum, completion: completion)
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let store = hkStore else { return completion(false) }
        
        store.requestAuthorization(
            toShare: [], // not updating any health data
            read: [
              getType(.distanceCycling),
              getType(.heartRate),
              getType(.stepCount)
            ]) {
            (success, error) in completion(success)
        }
    }
}

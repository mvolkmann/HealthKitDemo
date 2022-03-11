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
    
    private func characteristicType(_ typeId: HKCharacteristicTypeIdentifier) -> HKCharacteristicType {
        return HKCharacteristicType.characteristicType(forIdentifier: typeId)!
    }
    
    private func quantityType(_ typeId: HKQuantityTypeIdentifier) -> HKQuantityType {
        return HKQuantityType.quantityType(forIdentifier: typeId)!
    }
    
    func query(
        typeId: HKQuantityTypeIdentifier,
        options: HKStatisticsOptions,
        completion: @escaping (HKStatisticsCollection?) -> Void
    ) {
        let startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: Date(),
            options: .strictStartDate
        )
        let q = HKStatisticsCollectionQuery(
            quantityType: quantityType(typeId),
            quantitySamplePredicate: predicate,
            options: options,
            anchorDate: Date.mondayAt12AM(),
            intervalComponents: DateComponents(day: 1)
        )
        q.initialResultsHandler = { query, collection, error in completion(collection) }
        hkStore!.execute(q)
    }
    
    func queryCharacteristics(completion: @escaping (Characteristics) -> Void) {
        do {
            let sex = try hkStore!.biologicalSex()
            completion(Characteristics(sexEnum: sex.biologicalSex))
        } catch {
            print("error: \(error)")
        }
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
              characteristicType(.biologicalSex),
              quantityType(.distanceCycling),
              quantityType(.heartRate),
              quantityType(.stepCount)
            ]) {
            (success, error) in completion(success)
        }
    }
}

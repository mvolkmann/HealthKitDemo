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
        guard let hkStore = hkStore else { return }
        do {
            let dobComponents = try hkStore.dateOfBirthComponents()
            let sex = try hkStore.biologicalSex()
            queryQuantity(typeId: .height) { height in
                completion(Characteristics(
                    dateOfBirth: dobComponents.date,
                    height: height == nil ? 0 : height!.doubleValue(for: .inch()),
                    sexEnum: sex.biologicalSex
                ))
            }
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
    
    func queryQuantity(
        typeId: HKQuantityTypeIdentifier,
        completion: @escaping (HKQuantity?) -> Void
    ) {
        guard let hkStore = hkStore else {
            completion(nil)
            return
        }
        
        let type = quantityType(typeId)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: nil) {
            (query, results, error) in
            if let result = results?.first as? HKQuantitySample {
                completion(result.quantity)
            } else {
                completion(nil)
            }
        }
        hkStore.execute(query)
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
              characteristicType(.dateOfBirth),
              quantityType(.distanceCycling),
              quantityType(.heartRate),
              quantityType(.height),
              quantityType(.stepCount)
            ]) {
            (success, error) in completion(success)
        }
    }
}

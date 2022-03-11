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
        options: HKStatisticsOptions) async -> HKStatisticsCollection? {
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
            return await withCheckedContinuation { continuation in
                q.initialResultsHandler = { query, collection, error in continuation.resume(returning: collection) }
                hkStore!.execute(q)
            }
        }
    
    func queryCharacteristics() async -> Characteristics? {
        guard let hkStore = hkStore else { return nil }
        do {
            let dobComponents = try hkStore.dateOfBirthComponents()
            let sex = try hkStore.biologicalSex()
            let height = await queryQuantity(typeId: .height)
            let waist = await queryQuantity(typeId: .waistCircumference)
            return Characteristics(
                dateOfBirth: dobComponents.date,
                //height: height == nil ? 0 : height!.doubleValue(for: .inch()),
                heightInMeters: height == nil ? 0 : height!.doubleValue(for: .meter()),
                sexEnum: sex.biologicalSex,
                waistInMeters: waist == nil ? 0 : waist!.doubleValue(for: .meter())
            )
        } catch {
            print("error: \(error)")
            return nil
        }
    }
    
    func queryCycling() async -> HKStatisticsCollection? {
        return await query(typeId: .distanceCycling, options: .cumulativeSum)
    }
    
    func queryHeart() async -> HKStatisticsCollection? {
        return await query(typeId: .heartRate, options: .discreteAverage)
    }
    
    func queryQuantity(
        typeId: HKQuantityTypeIdentifier) async -> HKQuantity? {
            guard let hkStore = hkStore else { return nil }
            
            let type = quantityType(typeId)
            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: nil) {
                    (query1, results, error) in
                    if let result = results?.first as? HKQuantitySample {
                        continuation.resume(returning: result.quantity)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
                hkStore.execute(query)
            }
        }
    
    func querySteps() async -> HKStatisticsCollection? {
        return await query(typeId: .stepCount, options: .cumulativeSum)
    }
    
    func requestAuthorization() async throws -> Bool {
        guard let store = hkStore else { return false }
        
        try await store.__requestAuthorization(toShare: [], read: [
            characteristicType(.biologicalSex),
            characteristicType(.dateOfBirth),
            quantityType(.distanceCycling),
            quantityType(.heartRate),
            quantityType(.height),
            quantityType(.stepCount),
            quantityType(.waistCircumference),
        ])
        
        return true
    }
}

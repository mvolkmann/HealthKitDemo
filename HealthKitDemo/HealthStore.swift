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
    
    func queryAppleStats() async -> HKStatistics? {
        //TODO: Why doesn't this return a value?
        return await queryOne(typeId: .appleMoveTime, options: .mostRecent)
    }
    
    func queryCharacteristics() async -> Characteristics? {
        guard let hkStore = hkStore else { return nil }
        
        var dateOfBirth: Date? = nil
        do {
            dateOfBirth = try hkStore.dateOfBirthComponents().date
        } catch {
            // do nothing
        }
            
        var sex = HKBiologicalSex.notSet
        do {
            sex = try hkStore.biologicalSex().biologicalSex
        } catch {
            // do nothing
        }
        
        let height = await queryQuantity(typeId: .height)
        let waist = await queryQuantity(typeId: .waistCircumference)
        return Characteristics(
            dateOfBirth: dateOfBirth,
            heightInMeters: height == nil ? 0 : height!.doubleValue(for: .meter()),
            sexEnum: sex,
            waistInMeters: waist == nil ? 0 : waist!.doubleValue(for: .meter())
        )
    }
    
    func queryCollection(
        typeId: HKQuantityTypeIdentifier,
        options: HKStatisticsOptions
    ) async -> HKStatisticsCollection? {
        guard let hkStore = hkStore else { return nil }
        
        let startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: Date(),
            options: .strictStartDate
        )
        let q = HKStatisticsCollectionQuery(
            quantityType: quantityType(typeId),
            quantitySamplePredicate: predicate,
            options: .mostRecent,
            anchorDate: Date.mondayAt12AM(),
            intervalComponents: DateComponents(day: 1)
        )
        return await withCheckedContinuation { continuation in
            q.initialResultsHandler = { _, collection, error in
                continuation.resume(returning: collection)
            }
            hkStore.execute(q)
        }
    }
    
    func queryCycling() async -> HKStatisticsCollection? {
        return await queryCollection(typeId: .distanceCycling, options: .cumulativeSum)
    }
    
    func queryHeart() async -> HKStatisticsCollection? {
        return await queryCollection(typeId: .heartRate, options: .discreteAverage)
    }
    
    func queryOne(
        typeId: HKQuantityTypeIdentifier,
        options: HKStatisticsOptions
    ) async -> HKStatistics? {
        guard let hkStore = hkStore else { return nil }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: Date(),
            options: .strictStartDate
        )
        return await withCheckedContinuation { continuation in
            let q = HKStatisticsQuery(
                quantityType: quantityType(.appleMoveTime),
                quantitySamplePredicate: predicate,
                options: .mostRecent,
                completionHandler: {_, value, error in
                    if error == nil {
                        continuation.resume(returning: value!)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            )
            hkStore.execute(q)
        }
    }
    
    func queryRestingHeart() async -> HKStatisticsCollection? {
        return await queryCollection(typeId: .restingHeartRate, options: .discreteAverage)
    }
    
    func queryQuantity(
        typeId: HKQuantityTypeIdentifier) async -> HKQuantity? {
            guard let hkStore = hkStore else { return nil }
            
            let type = quantityType(typeId)
            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: nil) {
                    (query1, results, error) in
                    if error == nil {
                        continuation.resume(returning: nil)
                    } else if let result = results?.first as? HKQuantitySample {
                        continuation.resume(returning: result.quantity)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
                hkStore.execute(query)
            }
        }
    
    func querySteps() async -> HKStatisticsCollection? {
        return await queryCollection(typeId: .stepCount, options: .cumulativeSum)
    }
    
    func requestAuthorization() async throws -> Bool {
        guard let store = hkStore else { return false }
        
        try await store.__requestAuthorization(toShare: [], read: [
            characteristicType(.biologicalSex),
            characteristicType(.dateOfBirth),
            quantityType(.appleExerciseTime),
            quantityType(.appleMoveTime),
            quantityType(.appleStandTime),
            quantityType(.distanceCycling),
            quantityType(.heartRate),
            quantityType(.height),
            quantityType(.restingHeartRate),
            quantityType(.stepCount),
            quantityType(.waistCircumference),
        ])
        
        return true
    }
}

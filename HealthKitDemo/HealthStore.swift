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
    
    func predicate(days: Int) -> NSPredicate {
        let endDate = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: endDate)
        return HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
    }
    
    private func quantityType(_ typeId: HKQuantityTypeIdentifier) -> HKQuantityType {
        return HKQuantityType.quantityType(forIdentifier: typeId)!
    }
    
    func queryActivity() async -> [HKActivitySummary]? {
        guard let hkStore = hkStore else { return nil }
        
        return await withCheckedContinuation { continuation in
            let q = HKActivitySummaryQuery(
                //TODO: Why do I need to ask for 8 days to get 7?
                predicate: predicate(days: 8),
                resultsHandler: {_, summaries, error in
                    if let error = error {
                        print("error = \(error.localizedDescription)")
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(returning: summaries)
                    }
                }
            )
            hkStore.execute(q)
        }
    }
    
    func quantityDoubleValue(_ quantity: HKQuantity?, unit: HKUnit) -> Double {
        return quantity == nil ? 0 : quantity!.doubleValue(for: unit)
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
        
        let bodyMass = await queryQuantity(typeId: .bodyMass)
        let heartRateQuantity = await queryQuantity(typeId: .heartRate)
        let height = await queryQuantity(typeId: .height)
        let waist = await queryQuantity(typeId: .waistCircumference)
        return Characteristics(
            bodyMass: quantityDoubleValue(bodyMass, unit: .pound()),
            dateOfBirth: dateOfBirth,
            heartRate: Int(quantityDoubleValue(heartRateQuantity, unit: HKUnit(from: "count/min"))),
            heightInMeters: quantityDoubleValue(height, unit: .meter()),
            sexEnum: sex,
            waistInMeters: quantityDoubleValue(waist, unit: .meter())
        )
    }
    
    func queryCollection(
        typeId: HKQuantityTypeIdentifier,
        options: HKStatisticsOptions
    ) async -> HKStatisticsCollection? {
        guard let hkStore = hkStore else { return nil }
        
        let q = HKStatisticsCollectionQuery(
            quantityType: quantityType(typeId),
            quantitySamplePredicate: predicate(days: 7),
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
    
    func queryQuantity(
        typeId: HKQuantityTypeIdentifier) async -> HKQuantity? {
            print("HealthStore.queryQuantity: typeId = \(typeId.rawValue)")
            guard let hkStore = hkStore else { return nil }
            
            // Sort so the most recent value is first.
            let sortDescriptors = [
                NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            ]
            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: quantityType(typeId),
                    predicate: nil,
                    //predicate: predicate(days: 1), //TODO: Why doesn't this work?
                    limit: 1,
                    sortDescriptors: sortDescriptors
                ) {
                    (query1, results, error) in
                    if let error = error {
                        print("queryQuantity: error = \(error.localizedDescription)")
                        continuation.resume(returning: nil)
                    } else if let results = results {
                        if let result = results.first as? HKQuantitySample {
                            print("queryQuantity: result = \(result)")
                            continuation.resume(returning: result.quantity)
                        } else {
                            print("queryQuantity: empty result set")
                            continuation.resume(returning: nil)
                        }
                    } else {
                        print("queryQuantity: no results or error")
                        continuation.resume(returning: nil)
                    }
                }
                hkStore.execute(query)
            }
        }
    
    func queryRestingHeart() async -> HKStatisticsCollection? {
        return await queryCollection(typeId: .restingHeartRate, options: .discreteAverage)
    }
    
    func querySteps() async -> HKStatisticsCollection? {
        return await queryCollection(typeId: .stepCount, options: .cumulativeSum)
    }
    
    func requestAuthorization() async throws -> Bool {
        guard let store = hkStore else { return false }
        
        try await store.__requestAuthorization(
            // The app can update these.
            toShare: [
                quantityType(.bodyMass),
                quantityType(.waistCircumference),
            ],
            read: [
                HKObjectType.activitySummaryType(),
                characteristicType(.biologicalSex),
                characteristicType(.dateOfBirth),
                quantityType(.appleExerciseTime),
                quantityType(.appleMoveTime),
                quantityType(.appleStandTime),
                quantityType(.bodyMass),
                quantityType(.distanceCycling),
                quantityType(.heartRate),
                quantityType(.height),
                quantityType(.restingHeartRate),
                quantityType(.stepCount),
                quantityType(.waistCircumference),
            ]
        )
        
        return true
    }
    
    func saveQuantity(
        typeId: HKQuantityTypeIdentifier,
        unit: HKUnit,
        value: Double
    ) async {
        do {
            try await saveQuantityThrowing(typeId: typeId, unit: unit, value: value)
        } catch {
            print("error writing \(typeId.rawValue): \(error.localizedDescription)")
        }
    }
    
    func saveQuantityThrowing(
        typeId: HKQuantityTypeIdentifier,
        unit: HKUnit,
        value: Double
    ) async throws {
        guard let store = hkStore else {
            throw RuntimeError("HealthStore.saveQuantity: HKHealthStore not created")
        }
        
        let date = Date()
        let sample = HKQuantitySample.init(
            type: quantityType(typeId),
            quantity: HKQuantity.init(unit: unit, doubleValue: value),
            start: date,
            end: date
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            store.save(sample) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

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
        //return HKObjectType.quantityType(forIdentifier: typeId)!
        return HKQuantityType.quantityType(forIdentifier: typeId)!
    }
    
    func queryActivity() async -> [HKActivitySummary]? {
        guard let hkStore = hkStore else { return nil }
        
        let endDate = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)
        
        let units: Set<Calendar.Component> = [.day, .month, .year, .era]
        var startDateComponents = calendar.dateComponents(units, from: startDate!)
        startDateComponents.calendar = calendar
        
        var endDateComponents = calendar.dateComponents(units, from: endDate)
        endDateComponents.calendar = calendar
        
        let predicate = HKQuery.predicate(
            forActivitySummariesBetweenStart: startDateComponents,
            end: endDateComponents
        )
        
        return await withCheckedContinuation { continuation in
            let q = HKActivitySummaryQuery(
                predicate: predicate,
                resultsHandler: {_, summaries, error in
                    if let error = error {
                        print("error = \(error.localizedDescription)")
                        continuation.resume(returning: nil)
                    } else {
                        /*
                        if let summaries = summaries {
                            print("summaries = \(summaries)")
                            let first = summaries.isEmpty ? nil : summaries.first
                            continuation.resume(returning: first)
                        } else {
                            continuation.resume(returning: nil)
                        }
                        */
                        continuation.resume(returning: summaries)
                    }
                }
            )
            hkStore.execute(q)
        }
    }
    
    /*
    func queryAppleStats() async -> HKStatistics? {
        //TODO: Why doesn't this return a value?
        return await queryOne(typeId: .appleMoveTime)
    }
    */
    
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
        let height = await queryQuantity(typeId: .height)
        let waist = await queryQuantity(typeId: .waistCircumference)
        return Characteristics(
            bodyMass: bodyMass == nil ? 0 : bodyMass!.doubleValue(for: .pound()),
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
        
        let endDate = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
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
    
    /*
    func queryOne(
        typeId: HKQuantityTypeIdentifier,
    ) async -> HKStatistics? {
        guard let hkStore = hkStore else { return nil }
        
        let predicate = HKQuery.predicateForObject(with: typeId)(
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
    */
    
    func queryQuantity(
        typeId: HKQuantityTypeIdentifier) async -> HKQuantity? {
            guard let hkStore = hkStore else { return nil }
            
            let type = quantityType(typeId)
            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: type,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: nil
                ) {
                    (query1, results, error) in
                    if let error = error {
                        print("queryQuantity: error = \(error)")
                        continuation.resume(returning: nil)
                    } else if let results = results {
                        if let result = results.first as? HKQuantitySample {
                            continuation.resume(returning: result.quantity)
                        } else {
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
    ) async -> Bool {
        guard let store = hkStore else { return false }
        
        let type = quantityType(typeId)
        
        let endDate = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -1, to: endDate)!
        
        let sample = HKQuantitySample.init(
            type: type,
            quantity: HKQuantity.init(unit: unit, doubleValue: value),
            start: startDate,
            end: startDate
        )
        
        return await withCheckedContinuation { continuation in
            store.save(sample) { success, error in
                if let error = error {
                    print("save error = \(error)")
                    continuation.resume(returning: false)
                } else {
                    print("save success")
                    continuation.resume(returning: true)
                }
            }
        }
    }
}

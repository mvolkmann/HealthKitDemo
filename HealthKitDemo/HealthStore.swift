import Foundation
import HealthKit

class HealthStore {
    // This assumes that HKHealthStore.isHealthDataAvailable()
    // has already been checked.
    var store = HKHealthStore()
    
    private func characteristicType(
        _ typeId: HKCharacteristicTypeIdentifier
    ) -> HKCharacteristicType {
        return HKCharacteristicType.characteristicType(forIdentifier: typeId)!
    }
    
    func predicate(days: Int) -> NSPredicate {
        let calendar = Calendar.current
        let startDate = calendar.date(
            byAdding: .day,
            value: -(days - 1),
            to: Date()
        )
        return HKQuery.predicateForSamples(
            withStart: startDate,
            end: nil, // runs through the current time
            options: .strictStartDate
        )
    }
    
    private func quantityType(
        _ typeId: HKQuantityTypeIdentifier
    ) -> HKQuantityType {
        return HKQuantityType.quantityType(forIdentifier: typeId)!
    }
    
    func queryActivity() async -> [HKActivitySummary]? {
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
            store.execute(q)
        }
    }
    
    func quantityDoubleValue(_ quantity: HKQuantity?, unit: HKUnit) -> Double {
        return quantity == nil ? 0 : quantity!.doubleValue(for: unit)
    }
    
    func queryCharacteristics() async -> Characteristics? {
        var dateOfBirth: Date? = nil
        do {
            dateOfBirth = try store.dateOfBirthComponents().date
        } catch {
            // do nothing
        }
            
        var sex = HKBiologicalSex.notSet
        do {
            sex = try store.biologicalSex().biologicalSex
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
            heartRate: Int(quantityDoubleValue(
                heartRateQuantity,
                unit: HKUnit(from: "count/min")
            )),
            heightInMeters: quantityDoubleValue(height, unit: .meter()),
            sexEnum: sex,
            waistInMeters: quantityDoubleValue(waist, unit: .meter())
        )
    }
    
    func queryCollection(
        typeId: HKQuantityTypeIdentifier,
        options: HKStatisticsOptions
    ) async -> HKStatisticsCollection? {
        let q = HKStatisticsCollectionQuery(
            quantityType: quantityType(typeId),
            quantitySamplePredicate: predicate(days: 7),
            options: options,
            anchorDate: Date.mondayAt12AM(),
            intervalComponents: DateComponents(day: 1)
        )
        return await withCheckedContinuation { continuation in
            q.initialResultsHandler = { _, collection, error in
                continuation.resume(returning: collection)
            }
            store.execute(q)
        }
    }
    
    func queryCycling() async -> HKStatisticsCollection? {
        return await queryCollection(
            typeId: .distanceCycling,
            options: .cumulativeSum
        )
    }
    
    /*
    private func observeFalls() {
        let falls = quantityType(.numberOfTimesFallen),
        let query = HKObserverQuery(sampleType: falls, predicate: nil) { query, handler, error in
            self.checkNewFalls()
            handler()
        }
        store.execute(query)
    }
    
    private func checkNewFalls() {
        let falls = quantityType(.numberOfTimesFallen),
        let query = HKObserverQuery(sampleType: falls, predicate: nil) { query, handler, error in
        let query = HKAnchoredObjectQuery(type: falls, predicate: nil, anchor: lastAnchor, limit: HKObjectQueryNoLimit) { query, sample, deleted, anchor, error in
            defer { self.lastAnchor = anchor }
            guard self.lastAnchor != nil else { return }
            guard sample?.isEmpty == false else { return }
            self.presentFallAlert()
        }
        store.execute(query)
    }
    */
    
    func queryHeart() async -> HKStatisticsCollection? {
        return await queryCollection(
            typeId: .heartRate,
            options: .discreteAverage
        )
    }
    
    func queryQuantity(
        typeId: HKQuantityTypeIdentifier) async -> HKQuantity? {
            // Sort so the most recent value is first.
            let sortDescriptors = [
                NSSortDescriptor(
                    key: HKSampleSortIdentifierStartDate,
                    ascending: false
                )
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
                            continuation.resume(returning: result.quantity)
                        } else {
                            print("queryQuantity: empty result set for \(typeId.rawValue)")
                            continuation.resume(returning: nil)
                        }
                    } else {
                        print("queryQuantity: no results or error")
                        continuation.resume(returning: nil)
                    }
                }
                store.execute(query)
            }
        }
    
    func queryRestingHeart() async -> HKStatisticsCollection? {
        return await queryCollection(
            typeId: .restingHeartRate,
            options: .discreteAverage
        )
    }
    
    func querySteps() async -> HKStatisticsCollection? {
        return await queryCollection(
            typeId: .stepCount,
            options: .cumulativeSum
        )
    }
    
    func requestAuthorization() async throws {
        // This throws if authorization could not be requested.
        // Not throwing is not an indication that the user
        // granted all the requested permissions.
        try await store.requestAuthorization(
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
                quantityType(.numberOfTimesFallen),
                quantityType(.restingHeartRate),
                quantityType(.stepCount),
                quantityType(.waistCircumference),
            ]
        )
    }
    
    func saveQuantity(
        typeId: HKQuantityTypeIdentifier,
        unit: HKUnit,
        value: Double
    ) async {
        do {
            try await saveQuantityThrowing(
                typeId: typeId,
                unit: unit,
                value: value
            )
        } catch {
            print("error writing \(typeId.rawValue): \(error.localizedDescription)")
        }
    }
    
    func saveQuantityThrowing(
        typeId: HKQuantityTypeIdentifier,
        unit: HKUnit,
        value: Double
    ) async throws {
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

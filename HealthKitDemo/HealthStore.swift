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
    
    func daysAgoPredicate(_ days: Int) -> NSPredicate {
        return HKQuery.predicateForSamples(
            withStart: Date.daysAgo(days),
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
                predicate: daysAgoPredicate(7),
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
            quantitySamplePredicate: daysAgoPredicate(7),
            options: options,
            anchorDate: Date.mondayAt12AM(), // defined in DateExtensions.swift
            intervalComponents: DateComponents(day: 1) // 1 per day
        )
        return await withCheckedContinuation { continuation in
            q.initialResultsHandler = { _, collection, error in
                if let error = error {
                    print("HealthStore.queryCollection: error \(error.localizedDescription)")
                    //TODO: How can you return an empty collection when there is an error?
                    //continuation.resume(returning: HKStatisticsCollection())
                    continuation.resume(returning: nil)
                } else {
                    continuation.resume(returning: collection)
                }
            }
            store.execute(q)
        }
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
    
    func queryWorkouts() async throws -> [HKSample]? {
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .running)
        let sourcePredicate = HKQuery.predicateForObjects(from: .default())
        let compound = NSCompoundPredicate(
            andPredicateWithSubpredicates: [workoutPredicate, sourcePredicate]
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: true
        )
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: compound,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let results = results {
                    print("HealthStore.queryWorkouts: results = \(results)")
                    continuation.resume(returning: results)
                } else {
                    print("queryWorkouts: no results or error")
                    continuation.resume(returning: nil)
                }
            }
            store.execute(query)
        }
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
                .activitySummaryType(),
                .workoutType(),
                characteristicType(.biologicalSex),
                characteristicType(.dateOfBirth),
                quantityType(.appleExerciseTime),
                quantityType(.appleMoveTime),
                quantityType(.appleStandTime),
                quantityType(.bodyMass),
                quantityType(.distanceCycling),
                quantityType(.distanceWalkingRunning),
                quantityType(.heartRate),
                quantityType(.heartRateVariabilitySDNN),
                quantityType(.headphoneAudioExposure),
                quantityType(.height),
                quantityType(.numberOfTimesFallen),
                quantityType(.restingHeartRate),
                quantityType(.stepCount),
                quantityType(.waistCircumference),
                quantityType(.walkingHeartRateAverage),
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

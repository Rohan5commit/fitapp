import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    struct ImportedWorkout: Identifiable {
        let id: UUID
        let date: Date
        let durationMinutes: Double
        let energyBurnedKilocalories: Double
    }

    @Published private(set) var authorizationGranted = false

    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationGranted = false
            return
        }

        let readTypes = Set([
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.workoutType()
        ].compactMap { $0 as HKObjectType? })
        let shareTypes: Set<HKSampleType> = [HKObjectType.workoutType()]

        let granted: Bool = try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: success)
            }
        }

        authorizationGranted = granted
    }

    func fetchTodayActiveEnergyBurned() async throws -> Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }

        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let value = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    func fetchTodayWorkoutCount() async throws -> Int {
        let workoutType = HKObjectType.workoutType()
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples?.count ?? 0)
            }

            healthStore.execute(query)
        }
    }

    func saveWorkout(
        startDate: Date,
        durationMinutes: Double,
        energyBurnedKilocalories: Double,
        metadata: [String: Any]? = nil
    ) async throws {
        let clampedDuration = max(durationMinutes, 1)
        let endDate = startDate.addingTimeInterval(clampedDuration * 60.0)
        let energyQuantity = energyBurnedKilocalories > 0
            ? HKQuantity(unit: .kilocalorie(), doubleValue: energyBurnedKilocalories)
            : nil

        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: startDate,
            end: endDate,
            duration: clampedDuration * 60.0,
            totalEnergyBurned: energyQuantity,
            totalDistance: nil,
            metadata: metadata
        )

        try await withCheckedThrowingContinuation { continuation in
            healthStore.save(workout) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if success {
                    continuation.resume(returning: ())
                } else {
                    let saveError = NSError(
                        domain: "FitMind.HealthKit",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "HealthKit workout save failed."]
                    )
                    continuation.resume(throwing: saveError)
                }
            }
        }
    }

    func fetchRecentWorkouts(days: Int) async throws -> [ImportedWorkout] {
        guard days > 0 else { return [] }

        let workoutType = HKObjectType.workoutType()
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout]) ?? []
                let mapped = workouts.map { workout in
                    ImportedWorkout(
                        id: workout.uuid,
                        date: workout.startDate,
                        durationMinutes: workout.duration / 60.0,
                        energyBurnedKilocalories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                    )
                }

                continuation.resume(returning: mapped)
            }

            healthStore.execute(query)
        }
    }
}

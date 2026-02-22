import Foundation
import HealthKit

@MainActor
final class HeartRateService: ObservableObject {
    @Published private(set) var currentHeartRate: Double = 0

    private let healthStore = HKHealthStore()
    private var query: HKAnchoredObjectQuery?

    func requestAuthorization() async {
        guard
            HKHealthStore.isHealthDataAvailable(),
            let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)
        else {
            return
        }

        _ = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            healthStore.requestAuthorization(toShare: nil, read: [heartRate]) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: success)
            }
        }
    }

    func start() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: .distantPast, end: nil, options: .strictEndDate)
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            Task { @MainActor in
                self?.handle(samples)
            }
        }

        query.updateHandler = { [weak self] _, samples, _, _, _ in
            Task { @MainActor in
                self?.handle(samples)
            }
        }

        self.query = query
        healthStore.execute(query)
    }

    func stop() {
        guard let query else { return }
        healthStore.stop(query)
    }

    private func handle(_ samples: [HKSample]?) {
        guard
            let quantitySample = samples?.last as? HKQuantitySample
        else {
            return
        }

        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let value = quantitySample.quantity.doubleValue(for: unit)
        currentHeartRate = value
    }
}

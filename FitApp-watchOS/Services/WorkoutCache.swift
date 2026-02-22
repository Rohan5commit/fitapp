import Foundation

struct WorkoutCache {
    private let key = "fitmind.watch.todayWorkout"

    func save(_ workout: WatchWorkoutDay) {
        if let data = try? JSONEncoder().encode(workout) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() -> WatchWorkoutDay? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(WatchWorkoutDay.self, from: data)
    }
}

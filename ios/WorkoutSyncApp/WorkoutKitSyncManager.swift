import Foundation
import WorkoutKit

@MainActor
@Observable final class WorkoutKitSyncManager {
    var payload: WeeklyPayload?
    var message = "Choose a weekly JSON file from Files."
    var busy = false
    var conflicts: [ScheduledWorkoutPlan] = []
    var plans: [(WorkoutItem, WorkoutPlan, DateComponents)] = []

    func load(_ url: URL) async {
        do {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            guard data.count <= 1_000_000 else { throw PlanError.invalid("File is too large") }
            let incoming = try JSONDecoder().decode(WeeklyPayload.self, from: data)
            guard incoming.version == 1, !incoming.workouts.isEmpty, Set(incoming.workouts.map(\.id)).count == incoming.workouts.count else { throw PlanError.invalid("Invalid version, empty week, or duplicate IDs") }
            let calendar = Calendar(identifier: .gregorian)
            func parseDate(_ value: String) throws -> DateComponents {
                let p = value.split(separator: "-").compactMap { Int($0) }
                guard p.count == 3, value.count == 10 else { throw PlanError.invalid("Invalid date: \(value)") }
                let c = DateComponents(calendar: calendar, year: p[0], month: p[1], day: p[2])
                guard let d = calendar.date(from: c), calendar.component(.year, from: d) == p[0], calendar.component(.month, from: d) == p[1], calendar.component(.day, from: d) == p[2] else { throw PlanError.invalid("Invalid date: \(value)") }
                return c
            }
            let start = try parseDate(incoming.weekStart)
            guard let startDate = calendar.date(from: start) else { throw PlanError.invalid("Invalid week start") }
            var converted: [(WorkoutItem, WorkoutPlan, DateComponents)] = []
            for item in incoming.workouts {
                let date = try parseDate(item.date)
                guard let d = calendar.date(from: date), let offset = calendar.dateComponents([.day], from: startDate, to: d).day, (0...6).contains(offset) else { throw PlanError.invalid("Workout date must fall within the week") }
                converted.append((item, try item.convert(), date))
            }
            payload = incoming
            plans = converted
            let existing = await WorkoutScheduler.shared.scheduledWorkouts
            let dates = Set(converted.map { "\($0.2.year ?? 0)-\($0.2.month ?? 0)-\($0.2.day ?? 0)" })
            conflicts = existing.filter { dates.contains("\($0.date.year ?? 0)-\($0.date.month ?? 0)-\($0.date.day ?? 0)") }
            message = "Review the week before scheduling. Existing workouts on these dates: \(conflicts.count)."
        } catch {
            payload = nil; plans = []; conflicts = []; message = error.localizedDescription
        }
    }
    func schedule() async {
        guard !plans.isEmpty else { return }
        busy = true
        defer { busy = false }
        guard WorkoutScheduler.isSupported else { message = "Workout scheduling is not available on this device."; return }
        guard await WorkoutScheduler.shared.requestAuthorization() == .authorized else { message = "Workout scheduling permission was not granted."; return }
        for (_, plan, date) in plans { await WorkoutScheduler.shared.schedule(plan, at: date) }
        let scheduled = await WorkoutScheduler.shared.scheduledWorkouts
        let found = plans.filter { entry in scheduled.contains { $0.plan.id == entry.1.id && $0.date.year == entry.2.year && $0.date.month == entry.2.month && $0.date.day == entry.2.day } }.count
        message = "Found \(found) of \(plans.count) workouts in the schedule. Check the Watch for delivery."
    }
}

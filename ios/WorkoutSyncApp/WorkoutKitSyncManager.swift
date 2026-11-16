import Foundation
import WorkoutKit

@MainActor
@Observable final class WorkoutKitSyncManager {
    var payload: WeeklyPayload?
    var message = "Choose a weekly JSON file from Files."
    var busy = false
    var conflicts: [ScheduledWorkoutPlan] = []
    var plans: [(WorkoutItem, WorkoutPlan, DateComponents)] = []

    private let savedKey = "workout-sync-draft-v1"
    private let initializedKey = "workout-sync-initialized-v1"
    var shouldLoadExample: Bool { !UserDefaults.standard.bool(forKey: initializedKey) }
    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: savedKey)
        UserDefaults.standard.set(true, forKey: initializedKey)
        payload = nil; plans = []; conflicts = []
        message = "Week cleared from this app. Scheduled workouts are unchanged."
    }

    func restore() async {
        guard let data = UserDefaults.standard.data(forKey: savedKey) else { return }
        do { try await accept(JSONDecoder().decode(WeeklyPayload.self, from: data)) } catch { message = "Could not restore the saved week: \(error.localizedDescription)" }
    }

    func add(_ item: WorkoutItem) async throws {
        let day = try parseDate(item.date)
        let calendar = Calendar(identifier: .gregorian)
        guard let selected = calendar.date(from: day) else { throw PlanError.invalid("Invalid workout date") }
        let start: String
        var entries: [WorkoutItem] = []
        if let current = payload {
            let begin = try parseDate(current.weekStart)
            guard let startDate = calendar.date(from: begin), let offset = calendar.dateComponents([.day], from: startDate, to: selected).day, (0...6).contains(offset) else { throw PlanError.invalid("Choose a date within the currently loaded week, or import another week first.") }
            start = current.weekStart
            entries = current.workouts
        } else {
            let now = calendar.startOfDay(for: Date())
            let selectedDay = calendar.startOfDay(for: selected)
            let offset = calendar.dateComponents([.day], from: now, to: selectedDay).day ?? -1
            let startDay = (0...6).contains(offset) ? now : selectedDay
            let parts = calendar.dateComponents([.year, .month, .day], from: startDay)
            start = String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
        }
        entries.append(item)
        try await accept(WeeklyPayload(version: 1, weekStart: start, workouts: entries))
    }

    private func parseDate(_ value: String) throws -> DateComponents {
        let calendar = Calendar(identifier: .gregorian)
        let p = value.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3, value.count == 10 else { throw PlanError.invalid("Invalid date: \(value)") }
        let c = DateComponents(calendar: calendar, year: p[0], month: p[1], day: p[2])
        guard let d = calendar.date(from: c), calendar.component(.year, from: d) == p[0], calendar.component(.month, from: d) == p[1], calendar.component(.day, from: d) == p[2] else { throw PlanError.invalid("Invalid date: \(value)") }
        return c
    }

    func load(_ url: URL) async {
        do {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            guard data.count <= 1_000_000 else { throw PlanError.invalid("File is too large") }
            let incoming = try JSONDecoder().decode(WeeklyPayload.self, from: data)
            try await accept(incoming)

        } catch {
            message = error.localizedDescription
        }
    }
    private func accept(_ incoming: WeeklyPayload) async throws {
        guard incoming.version == 1, !incoming.workouts.isEmpty, Set(incoming.workouts.map(\.id)).count == incoming.workouts.count else { throw PlanError.invalid("Invalid version, empty week, or duplicate IDs") }
        let calendar = Calendar(identifier: .gregorian)
        let start = try parseDate(incoming.weekStart)
        guard let startDate = calendar.date(from: start) else { throw PlanError.invalid("Invalid week start") }
        var converted: [(WorkoutItem, WorkoutPlan, DateComponents)] = []
        for item in incoming.workouts {
            let date = try parseDate(item.date)
            guard let d = calendar.date(from: date), let offset = calendar.dateComponents([.day], from: startDate, to: d).day, (0...6).contains(offset) else { throw PlanError.invalid("Workout date must fall within the week") }
            converted.append((item, try item.convert(), date))
        }
        let encoded = try JSONEncoder().encode(incoming)
        let existing = await WorkoutScheduler.shared.scheduledWorkouts
        let dates = Set(converted.map { "\($0.2.year ?? 0)-\($0.2.month ?? 0)-\($0.2.day ?? 0)" })
        payload = incoming
        plans = converted
        conflicts = existing.filter { dates.contains("\($0.date.year ?? 0)-\($0.date.month ?? 0)-\($0.date.day ?? 0)") }
        UserDefaults.standard.set(encoded, forKey: savedKey)
        UserDefaults.standard.set(true, forKey: initializedKey)
        message = "Review the week before scheduling. Existing workouts on these dates: \(conflicts.count)."
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

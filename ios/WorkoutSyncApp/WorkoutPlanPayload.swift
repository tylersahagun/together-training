import Foundation
import HealthKit
import WorkoutKit

struct WeeklyPayload: Codable {
    let version: Int
    let weekStart: String
    let workouts: [WorkoutItem]
}
struct WorkoutItem: Codable, Identifiable {
    let id: UUID
    let date: String
    let title: String
    let activity: String
    let location: String
    let kind: String
    let steps: [PlanStep]

    func convert() throws -> WorkoutPlan {
        let activityType: HKWorkoutActivityType
        switch activity {
        case "running": activityType = .running
        case "walking": activityType = .walking
        case "traditionalStrengthTraining": activityType = .traditionalStrengthTraining
        case "functionalStrengthTraining": activityType = .functionalStrengthTraining
        case "mindAndBody": activityType = .mindAndBody
        case "golf": activityType = .golf
        default: throw PlanError.invalid("Unsupported activity: \(activity)")
        }
        let place: HKWorkoutSessionLocationType
        switch location {
        case "indoor": place = .indoor
        case "outdoor": place = .outdoor
        case "unknown": place = .unknown
        default: throw PlanError.invalid("Invalid location")
        }
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty, !steps.isEmpty else { throw PlanError.invalid("Missing workout title or steps") }
        if kind == "single" {
            guard steps.count == 1, steps[0].heartRateZone == nil else { throw PlanError.invalid("Single-goal workouts require one step and no alert") }
            let goal = try steps[0].workoutGoal()
            guard SingleGoalWorkout.supportsActivity(activityType), SingleGoalWorkout.supportsGoal(goal, activity: activityType, location: place) else { throw PlanError.invalid("Single-goal activity or goal is unsupported") }
            return WorkoutPlan(.goal(SingleGoalWorkout(activity: activityType, location: place, goal: goal)), id: id)
        }
        guard kind == "custom", CustomWorkout.supportsActivity(activityType) else { throw PlanError.invalid("Custom activity is unsupported") }
        guard (!steps.contains(where: { $0.purpose == "warmup" }) || steps.first?.purpose == "warmup"), steps.filter({ $0.purpose == "warmup" }).count <= 1, steps.filter({ $0.purpose == "cooldown" }).count == 1, let last = steps.last, last.purpose == "cooldown", last.goal == "time", (last.seconds ?? 0) >= 180 else { throw PlanError.invalid("A custom workout needs a final cooldown of at least three minutes") }
        var warmup: WorkoutStep?
        var cooldown: WorkoutStep?
        var intervals: [IntervalStep] = []
        for step in steps {
            let goal = try step.workoutGoal()
            guard CustomWorkout.supportsGoal(goal, activity: activityType, location: place) else { throw PlanError.invalid("Goal unsupported for \(step.name)") }
            var alert: (any WorkoutAlert)?
            if let zone = step.heartRateZone {
                guard (1...5).contains(zone) else { throw PlanError.invalid("Invalid heart-rate zone") }
                let candidate = HeartRateZoneAlert(zone: zone)
                guard CustomWorkout.supportsAlert(candidate, activity: activityType, location: place) else { throw PlanError.invalid("Heart-rate alert unsupported for \(step.name)") }
                alert = candidate
            }
            let native = WorkoutStep(goal: goal, alert: alert, displayName: step.name)
            switch step.purpose {
            case "warmup": warmup = native
            case "cooldown": cooldown = native
            case "work": intervals.append(IntervalStep(.work, step: native))
            case "recovery": intervals.append(IntervalStep(.recovery, step: native))
            default: throw PlanError.invalid("Invalid step purpose")
            }
        }
        guard !intervals.isEmpty else { throw PlanError.invalid("A custom workout needs a work or recovery step") }
        return WorkoutPlan(.custom(CustomWorkout(activity: activityType, location: place, displayName: title, warmup: warmup, blocks: [IntervalBlock(steps: intervals)], cooldown: cooldown)), id: id)
    }
}
struct PlanStep: Codable, Identifiable {
    var id: String { "\(purpose)-\(name)-\(goal)-\(seconds ?? 0)" }
    let purpose: String
    let name: String
    let goal: String
    let seconds: Double?
    let heartRateZone: Int?
    func workoutGoal() throws -> WorkoutGoal {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { throw PlanError.invalid("Missing step name") }
        switch goal {
        case "open": return .open
        case "time": guard let seconds, seconds > 0, seconds <= 86400 else { throw PlanError.invalid("Invalid step duration") }; return .time(seconds, .seconds)
        default: throw PlanError.invalid("Unknown goal")
        }
    }
}
enum PlanError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case .invalid(let message) = self { message } else { nil } }
}

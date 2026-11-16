import SwiftUI
import UniformTypeIdentifiers
import WorkoutKit

struct ContentView: View {
    @State private var manager = WorkoutKitSyncManager()
    @State private var selecting = false
    @State private var confirming = false
    @State private var preview: WorkoutPlan?
    private let example = WorkoutItem(
        id: UUID(uuidString: "8B7B7562-F0BD-49F5-8196-188E8A38B290")!, date: "Example", title: "Strength session",
        activity: "traditionalStrengthTraining", location: "indoor", kind: "custom",
        steps: [
            PlanStep(purpose: "warmup", name: "Warm up", goal: "time", seconds: 300, heartRateZone: nil),
            PlanStep(purpose: "work", name: "Squat · 8–10 reps", goal: "open", seconds: nil, heartRateZone: nil),
            PlanStep(purpose: "recovery", name: "Rest", goal: "time", seconds: 90, heartRateZone: nil),
            PlanStep(purpose: "cooldown", name: "Slow breathing", goal: "time", seconds: 180, heartRateZone: nil)
        ])

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Plan on iPhone. Follow on Watch.", systemImage: "applewatch")
                        .font(.headline)
                    Text("Import a week to review each step before scheduling it in the Workout app.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button("Import weekly plan", systemImage: "folder") { selecting = true }
                    Text(manager.message).font(.footnote).foregroundStyle(.secondary)
                }
                Section("Explore the preview") {
                    NavigationLink {
                        WorkoutDetailView(workout: example, plan: nil, isExample: true) { _ in }
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text("See an example workout")
                                Text("Explore a sample without scheduling it").font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "eye") }
                    }
                }
                if let payload = manager.payload {
                    Section("Week of \(payload.weekStart)") {
                        ForEach(payload.workouts) { workout in
                            NavigationLink {
                                WorkoutDetailView(workout: workout, plan: manager.plans.first(where: { $0.0.id == workout.id })?.1, isExample: false) { preview = $0 }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workout.title).font(.headline)
                                    Text("\(workout.date) · \(workout.steps.count) steps").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    if !manager.conflicts.isEmpty {
                        Section("Existing workouts on these dates") {
                            ForEach(manager.conflicts, id: \.plan.id) { conflict in
                                Text("\(conflict.date.year ?? 0)-\(conflict.date.month ?? 0)-\(conflict.date.day ?? 0) · \(conflict.plan.id.uuidString)").font(.caption)
                            }
                        }
                    }
                    Section {
                        Button("Schedule week on Apple Watch") { confirming = true }.disabled(manager.busy)
                        Text("Workouts are scheduled by day. Existing workouts on these dates are listed above.").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Workout Sync")
            .fileImporter(isPresented: $selecting, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url): Task { await manager.load(url) }
                case .failure(let error): manager.message = error.localizedDescription
                }
            }
            .confirmationDialog("Schedule this week?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Schedule \(manager.plans.count) workouts") { Task { await manager.schedule() } }
            } message: { Text("Existing workouts on these dates: \(manager.conflicts.count). Existing workouts with different IDs are not removed.") }
            .sheet(item: $preview) { plan in WorkoutPreviewSheet(plan: plan) }
        }
    }
}

private struct WorkoutDetailView: View {
    let workout: WorkoutItem
    let plan: WorkoutPlan?
    let isExample: Bool
    let showNative: (WorkoutPlan) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(isExample ? "EXAMPLE WORKOUT" : workout.date.uppercased())
                        .font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    Text(workout.title).font(.largeTitle.bold())
                    Text(isExample ? "A sample to explore, not a personalized plan." : "\(workout.steps.count) steps · \(workout.location.capitalized)")
                        .foregroundStyle(.secondary)
                }
                WatchStepPreview(title: workout.title, steps: workout.steps)
                    .frame(maxWidth: .infinity)
                if let plan {
                    Button("Open Apple Workout preview", systemImage: "applewatch") { showNative(plan) }
                        .buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
                    Text("Apple’s preview shows the WorkoutKit composition before scheduling.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Workout steps").font(.title3.bold())
                    ForEach(Array(workout.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)").font(.caption.bold()).foregroundStyle(.secondary).frame(width: 22)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(step.name).fontWeight(.medium)
                                Text(step.purpose.capitalized + (step.goal == "open" ? " · Open" : step.seconds.map { " · \(Int($0)) sec" } ?? ""))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        Divider()
                    }
                }
            }.padding(20)
        }
        .navigationTitle("Workout preview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WorkoutPreviewSheet: View {
    let plan: WorkoutPlan
    @Environment(\.dismiss) private var dismiss
    @State private var showingPreview = true
    var body: some View {
        Button("Close") { dismiss() }
            .workoutPreview(plan, isPresented: $showingPreview)
    }
}

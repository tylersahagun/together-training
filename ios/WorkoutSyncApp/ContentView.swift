import SwiftUI
import UniformTypeIdentifiers
import WorkoutKit

struct ContentView: View {
    @State private var manager = WorkoutKitSyncManager()
    @State private var selecting = false
    @State private var confirming = false
    @State private var preview: WorkoutPlan?
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Import weekly plan", systemImage: "folder") { selecting = true }
                    Text(manager.message).font(.footnote).foregroundStyle(.secondary)
                }
                if let payload = manager.payload {
                    Section("Week of \(payload.weekStart)") {
                        ForEach(payload.workouts) { workout in
                            DisclosureGroup("\(workout.date) · \(workout.title)") {
                                Text("\(workout.activity) · \(workout.location)").font(.caption)
                                Text(workout.steps.map { "\($0.purpose.capitalized): \($0.name)\($0.seconds.map { " · \(Int($0)) sec" } ?? "")" }.joined(separator: "\n"))
                                if let plan = manager.plans.first(where: { $0.0.id == workout.id })?.1 {
                                    Button("Preview in Workout") { preview = plan }
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
                        Text("Workouts are scheduled by day. Review any existing matching workout IDs before continuing.").font(.footnote).foregroundStyle(.secondary)
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
            .sheet(item: $preview) { plan in
                WorkoutPreviewSheet(plan: plan)
            }
        }
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

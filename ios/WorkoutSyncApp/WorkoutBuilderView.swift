import SwiftUI

private struct DraftStep: Identifiable {
    let id = UUID()
    var name = ""
    var purpose = "work"
    var goal = "open"
    var seconds = 90
}

struct WorkoutBuilderView: View {
    let manager: WorkoutKitSyncManager
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var date = Date()
    @State private var activity = "traditionalStrengthTraining"
    @State private var location = "indoor"
    @State private var steps: [DraftStep] = []
    @State private var cooldownMinutes = 3
    @State private var error: String?
    @State private var saving = false
    private let activities = [("Strength", "traditionalStrengthTraining"), ("Functional strength", "functionalStrengthTraining"), ("Walk", "walking"), ("Run", "running"), ("Mind and body", "mindAndBody")]

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    TextField("Workout name", text: $title)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Activity", selection: $activity) {
                        ForEach(activities, id: \.1) { pair in Text(pair.0).tag(pair.1) }
                    }
                    Picker("Location", selection: $location) {
                        Text("Indoors").tag("indoor")
                        Text("Outdoors").tag("outdoor")
                    }
                }
                Section {
                    ForEach($steps) { $step in
                        VStack(alignment: .leading) {
                            TextField("Step name, e.g. Squat · 8 reps", text: $step.name)
                            Picker("Step type", selection: $step.purpose) {
                                Text("Work").tag("work")
                                Text("Recovery").tag("recovery")
                            }.pickerStyle(.segmented)
                            Picker("Goal", selection: $step.goal) {
                                Text("Open").tag("open")
                                Text("Timed").tag("time")
                            }.pickerStyle(.segmented)
                            if step.goal == "time" { Stepper("\(step.seconds) sec", value: $step.seconds, in: 30...10800, step: 30) }
                        }.padding(.vertical, 6)
                    }.onDelete { steps.remove(atOffsets: $0) }.onMove { steps.move(fromOffsets: $0, toOffset: $1) }
                    Button("Add step", systemImage: "plus.circle") { steps.append(DraftStep()) }
                } header: { Text("Steps") } footer: { Text("Add exercises or intervals in order. Swipe a step to delete it; use Edit to reorder.") }
                Section("Cooldown") {
                    Stepper("Slow breathing · \(cooldownMinutes) min", value: $cooldownMinutes, in: 3...5)
                }
                if let error { Section { Text(error).foregroundStyle(.red) } }
                Section { Text("Build your own session. The app checks device support, but does not yet evaluate training load or recovery rules.").font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("Build workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("Add to week") { Task { await save() } }.disabled(saving) }
                ToolbarItem(placement: .topBarLeading) { EditButton() }
            }
        }
    }
    private func save() async {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !steps.isEmpty, steps.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { error = "Enter a workout name and at least one named step."; return }
        saving = true
        defer { saving = false }
        let day = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        let dateString = String(format: "%04d-%02d-%02d", day.year!, day.month!, day.day!)
        var output = steps.map { PlanStep(purpose: $0.purpose, name: $0.name, goal: $0.goal, seconds: $0.goal == "time" ? Double($0.seconds) : nil, heartRateZone: nil) }
        output.append(PlanStep(purpose: "cooldown", name: "Slow breathing", goal: "time", seconds: Double(cooldownMinutes * 60), heartRateZone: nil))
        let item = WorkoutItem(id: UUID(), date: dateString, title: title, activity: activity, location: location, kind: "custom", steps: output)
        do { try await manager.add(item); dismiss() } catch { self.error = error.localizedDescription }
    }
}

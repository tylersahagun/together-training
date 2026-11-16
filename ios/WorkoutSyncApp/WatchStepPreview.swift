import SwiftUI

/// An illustrative view of the data sent to WorkoutKit, not Apple's Workout UI.
struct WatchStepPreview: View {
    let title: String
    let steps: [PlanStep]
    @State private var selected = 0

    private var step: PlanStep? { steps.indices.contains(selected) ? steps[selected] : nil }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack {
                    Text("WORKOUT PREVIEW")
                    Spacer()
                    Text("\(min(selected + 1, steps.count)) / \(steps.count)")
                }
                .font(.caption2.weight(.bold)).foregroundStyle(.gray)
                Spacer(minLength: 4)
                if let step {
                    HStack {
                        Text(step.purpose.uppercased()).font(.caption.weight(.bold)).foregroundStyle(.green)
                        Spacer()
                    }
                    Text(step.name).font(.system(size: 24, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .minimumScaleFactor(0.7)
                    Text(step.goal == "open" ? "Open · advance when ready" : duration(step.seconds))
                        .font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let zone = step.heartRateZone {
                        Label("Heart rate · Zone \(zone)", systemImage: "heart.fill")
                            .font(.caption).foregroundStyle(.pink).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Spacer(minLength: 4)
                HStack(spacing: 4) {
                    ForEach(steps.indices, id: \.self) { index in
                        Capsule().fill(index == selected ? Color.green : Color.white.opacity(0.2)).frame(height: 3)
                    }
                }.accessibilityHidden(true)
            }
            .padding(20)
            .frame(width: 250, height: 260)
            .foregroundStyle(.white)
            .background(.black, in: RoundedRectangle(cornerRadius: 48))
            .overlay(RoundedRectangle(cornerRadius: 48).stroke(.gray.opacity(0.35), lineWidth: 4))
            .accessibilityElement(children: .combine)
            HStack(spacing: 24) {
                Button("Previous", systemImage: "chevron.left") { selected -= 1 }
                    .disabled(selected == 0)
                Button("Next", systemImage: "chevron.right") { selected += 1 }
                    .disabled(selected >= steps.count - 1)
            }.font(.subheadline.weight(.medium))
            Text("Illustration of your steps. The Workout app’s appearance and controls may differ.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
    }

    private func duration(_ seconds: Double?) -> String {
        guard let seconds else { return "Timed step" }
        let value = Int(seconds)
        if value % 60 == 0 { return "\(value / 60) min" }
        return "\(value / 60):\(String(format: "%02d", value % 60)) min"
    }
}

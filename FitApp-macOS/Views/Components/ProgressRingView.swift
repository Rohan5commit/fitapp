import SwiftUI

struct ProgressRingView: View {
    let title: String
    let value: Double
    let detail: String

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: max(0, min(value, 1)))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.mint, .blue]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text("\(Int(max(0, min(value, 1)) * 100))%")
                    .font(.headline)
            }
            .frame(width: 110, height: 110)

            Text(title)
                .font(.subheadline.bold())
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

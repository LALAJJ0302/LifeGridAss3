import SwiftUI

struct LifeGridPageHeader: View {
    let context: String
    let title: String
    let subtitle: String
    let symbol: String
    let accent: Color
    var actionSymbol: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 68, height: 68)

                RoundedRectangle(cornerRadius: 16)
                    .fill(accent.gradient)
                    .frame(width: 50, height: 50)

                Image(systemName: symbol)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(context.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.3)
                    .foregroundStyle(accent)

                Text(title)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if let actionSymbol, let action {
                Button(action: action) {
                    Image(systemName: actionSymbol)
                        .font(.headline)
                        .frame(width: 42, height: 42)
                        .background(.regularMaterial, in: Circle())
                }
                .tint(accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

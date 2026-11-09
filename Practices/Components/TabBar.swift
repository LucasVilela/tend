import SwiftUI

/// The custom tab bar: icon over an 11 pt label, active in primary, a wavy line on top.
struct TabBar: View {
    @Binding var selection: AppTab
    /// Height above the home indicator: wave (6) + padding (5 + 2) + items (48).
    static let height: CGFloat = 61

    var body: some View {
        VStack(spacing: 0) {
            WaveDivider()
            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    let active = tab == selection
                    Button { selection = tab } label: {
                        VStack(spacing: 4) {
                            IconView(icon: Icon(tab), size: 22, lineWidth: 1.4)
                            Text(tab.label)
                                .textStyle(active ? Theme.Font.tabLabel.with(weight: 500) : Theme.Font.tabLabel)
                        }
                        .foregroundStyle(active ? Theme.textPrimary : Theme.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.label)
                    .accessibilityAddTraits(active ? [.isSelected, .isButton] : .isButton)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 5)
            .padding(.bottom, 2)
        }
        .background(Theme.background.ignoresSafeArea(edges: .bottom))
    }
}

/// A plain screen header with a large title, used by the tabs.
struct ScreenTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .textStyle(Theme.Font.title)
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The "‹ Today" back button on pushed screens.
struct BackButton: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button { dismiss() } label: {
            HStack(spacing: 6) {
                IconView(icon: .chevronLeft, size: 20, lineWidth: 1.5)
                Text(title).textStyle(Theme.Font.body)
            }
            .foregroundStyle(Theme.textSecondary)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, -4)
        .accessibilityLabel("Back to \(title)")
    }
}

import SwiftUI

// MARK: - Labels

/// Small grey section label ("Check-ins", "How long?"), with an optional note on the right ("optional").
struct SectionLabel: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if let trailing { Text(trailing) }
        }
        .textStyle(Theme.Font.secondary)
        .foregroundStyle(Theme.textTertiary)
    }
}

// MARK: - Capsule switch

/// Two or three organic segments in an outlined capsule (Tracker | Guided, Image | Text, intensity).
struct CapsuleSwitch<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let label: (Value) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isOn = option == selection
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { selection = option }
                } label: {
                    Text(label(option))
                        .textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20))
                        .foregroundStyle(isOn ? Theme.textPrimary : Theme.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background {
                            if isOn { OrganicShape.capsule.fill(Theme.surfaceSelected) }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(3)
        .overlay(OrganicShape.capsule.strokeBorder(Theme.track, lineWidth: 1))
    }
}

// MARK: - Chips

/// An organic pill that can be selected; the selected chip gets an accent outline and a soft fill.
struct Chip: View {
    let title: String
    let selected: Bool
    var accent: Color = Theme.textPrimary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20))
                .foregroundStyle(selected ? Theme.textPrimary : Theme.textSecondary)
                .padding(.horizontal, 18)
                .frame(minHeight: 44)
                .background {
                    OrganicShape.capsule.fill(selected ? Theme.surfaceSelected : .clear)
                    OrganicShape.capsule.strokeBorder(selected ? accent : Theme.outline, lineWidth: selected ? 1.5 : 1)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Lays children out in rows, wrapping when a row is full.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = arrange(subviews, width: width)
        let height = rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let extra = rows[rows.count - 1].indices.isEmpty ? size.width : size.width + spacing
            if rows[rows.count - 1].width + extra > width && !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let current = rows.count - 1
            rows[current].width += rows[current].indices.isEmpty ? size.width : size.width + spacing
            rows[current].height = max(rows[current].height, size.height)
            rows[current].indices.append(index)
        }
        return rows
    }
}

// MARK: - Dot selector

/// Minutes as a row of numbers (5, 10, 15, 20, 30+); the picked one is bright with a dot under it.
struct DotSelector: View {
    let values: [Int]
    @Binding var selection: Int?
    var color: Color
    var numberSize: CGFloat = 22
    /// Optional selectors can be cleared by tapping the picked value again.
    var optional = false

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                ForEach(values, id: \.self) { value in
                    let isOn = value == selection
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selection = (optional && isOn) ? nil : value
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(value >= 30 ? "30+" : "\(value)")
                                .textStyle(Theme.Font.prompt.with(size: numberSize, lineHeight: numberSize + 6))
                                .foregroundStyle(isOn ? Theme.textPrimary : Theme.textTertiary)
                            OrganicShape.blob.fill(isOn ? color : .clear).frame(width: 5, height: 5)
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(value >= 30 ? "30 or more minutes" : "\(value) minutes")
                    .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
                }
            }
            Text("minutes")
                .textStyle(Theme.Font.micro)
                .foregroundStyle(Theme.textTertiary)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Buttons

/// Full-width organic pill in an accent colour with dark text.
struct PrimaryButton: View {
    let title: String
    var icon: Icon? = .check
    var color: Color
    var enabled = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon { IconView(icon: icon, size: 18, lineWidth: 1.8) }
                Text(title).textStyle(Theme.Font.body.with(weight: 500))
            }
            .foregroundStyle(Theme.onAccent)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(OrganicShape.capsule.fill(color))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.4)
        .disabled(!enabled)
    }
}

/// The floating + button: a 56 pt wobbling blob with a soft shadow.
struct FloatingActionButton: View {
    var color: Color
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            WobblingBlob { shape in
                ZStack {
                    shape.fill(color)
                    IconView(icon: .plus, size: 26, lineWidth: 1.8).foregroundStyle(Theme.onAccent)
                }
            }
            .frame(width: Tokens.Shape.fabSize, height: Tokens.Shape.fabSize)
            .shadow(color: .black.opacity(0.45), radius: 14, y: 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

extension View {
    /// Places a floating + button at the bottom right, above the tab bar.
    func floatingAction(color: Color, label: String, action: @escaping () -> Void) -> some View {
        overlay(alignment: .bottomTrailing) {
            FloatingActionButton(color: color, label: label, action: action)
                .padding(.trailing, Tokens.Shape.fabTrailingInset)
                .padding(.bottom, Tokens.Shape.fabAboveTabBar)
        }
    }
}

// MARK: - Sheets

/// Top bar of a full-screen sheet: close on the left, a centred title.
struct SheetHeader<Center: View>: View {
    var onClose: () -> Void
    @ViewBuilder var center: Center

    var body: some View {
        ZStack {
            center
            HStack {
                Button(action: onClose) {
                    IconView(icon: .close, size: 22, lineWidth: 1.5)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.leading, -10)
                .accessibilityLabel("Close")
                Spacer()
            }
        }
        .frame(minHeight: 44)
    }
}

extension SheetHeader where Center == AnyView {
    init(title: String, onClose: @escaping () -> Void) {
        self.onClose = onClose
        self.center = AnyView(
            Text(title)
                .textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20).with(weight: 500))
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
        )
    }
}

/// The big light sentence at the top of a logger sheet.
struct SheetPrompt: View {
    let text: String
    var body: some View {
        Text(text)
            .textStyle(TextStyleToken(size: 24, lineHeight: 32, weight: 300, tracking: -0.01))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Lays out a logger sheet: header, scrolling body, and a primary button pinned to the bottom.
struct SheetScaffold<Header: View, Content: View, Footer: View>: View {
    @ViewBuilder var header: Header
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) { content }
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            footer
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 12)
        }
        .background(Theme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

// MARK: - When row

/// "When · Today, 8:40 pm ›" between wavy lines; tapping it reveals a date-and-time wheel (no future dates).
struct WhenRow: View {
    @Binding var date: Date
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            WaveDivider()
            Button { withAnimation(.easeInOut(duration: 0.25)) { expanded.toggle() } } label: {
                HStack {
                    Text("When").textStyle(Theme.Font.body).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(Formats.whenLabel(date))
                        .textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20))
                        .foregroundStyle(Theme.textSecondary)
                    IconView(icon: .chevronRight, size: 18, lineWidth: 1.5)
                        .foregroundStyle(Theme.textTertiary)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("When, \(Formats.whenLabel(date))")
            .accessibilityHint(expanded ? "Hides the date picker" : "Shows a date picker")
            if expanded {
                DatePicker("When", selection: $date, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            }
            WaveDivider()
        }
    }
}

// MARK: - Underlined field

/// A borderless text field over a wavy underline that takes the accent colour while focused.
struct UnderlinedField: View {
    let placeholder: String
    @Binding var text: String
    var style: TextStyleToken = Theme.Font.body
    var accent: Color = Theme.textSecondary
    var lineLimit: ClosedRange<Int> = 1...6
    var minHeight: CGFloat = 0
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Theme.textTertiary), axis: .vertical)
                .lineLimit(lineLimit)
                .textStyle(style, monospacedDigits: false)
                .foregroundStyle(Theme.textPrimary)
                .tint(accent)
                .focused($focused)
                .frame(minHeight: minHeight, alignment: .topLeading)
                .accessibilityLabel(placeholder)
            WaveDivider(color: focused ? accent : Theme.wave)
                .animation(.easeOut(duration: 0.2), value: focused)
        }
    }
}

// MARK: - Bar chart

/// Seven bars for the rolling last 7 days with a dashed goal line. Bars at goal use `color`,
/// below goal `muted`, empty days a small dot. Today's label is bright.
struct MiniBarChart: View {
    struct Bar: Identifiable {
        let day: Date
        let minutes: Int
        let isToday: Bool
        var id: Date { day }
    }

    let bars: [Bar]
    let goal: Int
    var color: Color
    var muted: Color
    var height: CGFloat = 120
    var unit = "minutes"

    var body: some View {
        let top = Double(max(goal * 3 / 2, bars.map(\.minutes).max() ?? 0, 1))
        let goalY = height * (1 - CGFloat(Double(goal) / top))
        VStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: goalY))
                    p.addLine(to: CGPoint(x: 2000, y: goalY))
                }
                .stroke(Theme.outlineStrong, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .frame(height: height)
                .clipped()
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(bars) { bar in
                        ZStack(alignment: .bottom) {
                            if bar.minutes > 0 {
                                Capsule()
                                    .fill(bar.minutes >= goal ? color : muted)
                                    .frame(width: 6, height: max(10, height * CGFloat(Double(bar.minutes) / top)))
                            } else {
                                OrganicShape.blob.fill(Theme.outlineStrong).frame(width: 6, height: 6)
                                    .padding(.bottom, 2)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: height, alignment: .bottom)
                    }
                }
                .frame(height: height)
            }
            HStack(spacing: 0) {
                ForEach(bars) { bar in
                    Text(Formats.weekdayInitial(bar.day))
                        .textStyle(Theme.Font.micro)
                        .foregroundStyle(bar.isToday ? Theme.textPrimary : Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Last 7 days, goal \(goal) \(unit) a day")
        .accessibilityValue(bars.map { "\(Formats.shortDay($0.day)): \($0.minutes) \(unit)" }.joined(separator: ", "))
    }
}

// MARK: - Simple list row

/// Title over detail with an optional value on the right, as used in recent sessions and workouts.
struct DetailRow<Trailing: View>: View {
    let title: String
    let detail: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).textStyle(Theme.Font.body).foregroundStyle(Theme.textPrimary)
                Text(detail).textStyle(Theme.Font.caption).foregroundStyle(Theme.textTertiary)
            }
            Spacer(minLength: 8)
            trailing
        }
        .frame(minHeight: Tokens.Spacing.listRowMinHeight - 6)
        .accessibilityElement(children: .combine)
    }
}

/// Minutes as "10 min" (30 from the dot selector reads "30+ min" only where it came from that choice).
func minutesLabel(_ minutes: Int) -> String { "\(minutes) min" }

/// "2h 05m", "45m", "3h".
func durationLabel(_ minutes: Int) -> String {
    let h = minutes / 60, m = minutes % 60
    if h == 0 { return "\(m)m" }
    return m == 0 ? "\(h)h" : String(format: "%dh %02dm", h, m)
}

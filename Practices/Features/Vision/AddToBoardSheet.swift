import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Add a tile to the board (or edit one): a photo with an optional caption, or labelled text.
/// A goal can carry a month to keep in mind; nothing counts down or tracks.
struct AddToBoardSheet: View {
    let tile: VisionTile?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \VisionTile.order) private var tiles: [VisionTile]

    @State private var kind: TileKind = .text
    @State private var label: TextLabel = .goal
    @State private var text = ""
    @State private var dueMonth: Date?
    @State private var imageData: Data?
    @State private var heightClass: Int?
    @State private var caption = ""
    @State private var loaded = false

    @State private var choosingSource = false
    @State private var showingPhotos = false
    @State private var showingFiles = false
    @State private var photoItem: PhotosPickerItem?
    @State private var pickingMonth = false

    var body: some View {
        SheetScaffold {
            SheetHeader(title: tile == nil ? "Add to board" : "Edit tile") { dismiss() }
        } content: {
            CapsuleSwitch(options: [TileKind.image, .text], selection: $kind) { $0 == .image ? "Image" : "Text" }
            switch kind {
            case .image: imageForm
            case .text: textForm
            }
        } footer: {
            PrimaryButton(title: tile == nil ? "Add to board" : "Save changes", icon: tile == nil ? .plus : .check,
                          color: Theme.textPrimary, enabled: canSave, action: save)
        }
        .onAppear(perform: load)
        .confirmationDialog("Choose a photo", isPresented: $choosingSource) {
            Button("Photos") { showingPhotos = true }
            Button("Files") { showingFiles = true }
        }
        .photosPicker(isPresented: $showingPhotos, selection: $photoItem, matching: .images)
        .fileImporter(isPresented: $showingFiles, allowedContentTypes: [.image]) { result in
            guard case .success(let url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url) { use(data) }
        }
        .onChange(of: photoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) { use(data) }
            }
        }
        .sheet(isPresented: $pickingMonth) {
            MonthYearPicker(month: $dueMonth)
                .presentationDetents([.height(330)])
                .presentationBackground(Theme.background)
        }
    }

    // MARK: Image

    private var imageForm: some View {
        VStack(alignment: .leading, spacing: 28) {
            Button { choosingSource = true } label: {
                ZStack {
                    if let data = imageData, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill()
                            .frame(height: 240).frame(maxWidth: .infinity).clipped()
                            .clipShape(OrganicShape.card)
                        Text("Change photo")
                            .textStyle(Theme.Font.caption)
                            .foregroundStyle(Theme.onImage)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(OrganicShape.capsule.fill(Theme.scrim))
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, 14)
                    } else {
                        OrganicShape.card.strokeBorder(Theme.outlineStrong, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        VStack(spacing: 6) {
                            IconView(icon: .plus, size: 22, lineWidth: 1.5).foregroundStyle(Theme.textSecondary)
                                .padding(.bottom, 4)
                            Text("Choose a photo").textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20)).foregroundStyle(Theme.textPrimary)
                            Text("From Photos or Files").textStyle(Theme.Font.caption).foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .frame(height: 240)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(imageData == nil ? "Choose a photo from Photos or Files" : "Change photo")

            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(title: "Caption", trailing: "optional")
                UnderlinedField(placeholder: "e.g. Learn to surf", text: $caption, accent: Theme.textSecondary, lineLimit: 1...3)
            }
        }
    }

    private func use(_ data: Data) {
        guard let prepared = VisionLayout.preparedImageData(data) else { return }
        imageData = prepared.data
        heightClass = prepared.heightClass
    }

    // MARK: Text

    private var textForm: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(title: "Label")
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(TextLabel.allCases) { option in
                        Chip(title: option.name, selected: label == option) {
                            withAnimation(.easeInOut(duration: 0.2)) { label = option }
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(title: "Text")
                UnderlinedField(placeholder: placeholder, text: $text,
                                style: TextStyleToken(size: 22, lineHeight: 30, weight: 300, tracking: 0),
                                accent: Theme.textSecondary, lineLimit: 1...5, minHeight: 60)
            }
            if label == .goal {
                Button { pickingMonth = true } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("By when").textStyle(Theme.Font.body).foregroundStyle(Theme.textPrimary)
                            Text("Optional · just a date to keep in mind").textStyle(Theme.Font.caption).foregroundStyle(Theme.textTertiary)
                        }
                        Spacer()
                        Text(dueMonth.map { Formats.shortMonthAndYear($0) } ?? "None")
                            .textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20))
                            .foregroundStyle(Theme.textSecondary)
                        IconView(icon: .chevronRight, size: 18, lineWidth: 1.5).foregroundStyle(Theme.textTertiary)
                    }
                    .frame(minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("By when, \(dueMonth.map { Formats.monthAndYear($0) } ?? "none")")
                .waveBelow()
                .transition(.opacity)
            }
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(title: "On your board")
                VisionTileView(content: previewContent, width: 170)
                    .animation(.easeInOut(duration: 0.2), value: previewContent)
            }
        }
    }

    private var placeholder: String {
        switch label {
        case .goal: "Something you want to do"
        case .mantra: "A line to come back to"
        case .wordsForTheYear: "e.g. Steady · Present · Kind"
        case .quote: "Words that move you"
        case .reminder: "Something to remember"
        }
    }

    private var previewContent: TileContent {
        let shown = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return TileContent(kind: .text, text: shown.isEmpty ? placeholder : shown, label: label,
                           dueMonth: label == .goal ? dueMonth : nil, accentIndex: label == .goal ? goalAccentIndex : nil)
    }

    /// Goals rotate through four accents in the order they were created.
    private var goalAccentIndex: Int {
        if let tile, tile.textLabel == .goal, let index = tile.accentIndex { return index }
        return tiles.filter { $0.textLabel == .goal && $0 !== tile }.count % 4
    }

    // MARK: Save

    private var canSave: Bool {
        switch kind {
        case .image: imageData != nil
        case .text: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let tile else { return }
        kind = tile.kind
        label = tile.textLabel ?? .goal
        text = tile.text ?? ""
        dueMonth = tile.dueMonth
        imageData = tile.imageData
        heightClass = tile.heightClass
        caption = tile.caption ?? ""
    }

    private func save() {
        let target: VisionTile
        if let tile {
            target = tile
        } else {
            // New tiles go into the shorter column.
            let heights = (0..<2).map { column in
                tiles.filter { $0.column == column }.reduce(CGFloat(0)) { $0 + VisionLayout.estimatedHeight($1) + VisionLayout.gap }
            }
            let column = heights[1] < heights[0] ? 1 : 0
            let order = (tiles.filter { $0.column == column }.map(\.order).max() ?? -1) + 1
            target = VisionTile(kind: kind, column: column, order: order)
            context.insert(target)
        }
        target.kind = kind
        switch kind {
        case .image:
            target.imageData = imageData
            target.heightClass = heightClass
            let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
            target.caption = trimmed.isEmpty ? nil : trimmed
            target.text = nil
            target.textLabel = nil
            target.dueMonth = nil
            target.accentIndex = nil
        case .text:
            target.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            target.textLabel = label
            target.dueMonth = label == .goal ? dueMonth : nil
            target.accentIndex = label == .goal ? goalAccentIndex : nil
            target.imageData = nil
            target.heightClass = nil
            target.caption = nil
            target.subtitle = nil
        }
        try? context.save()
        dismiss()
    }
}

/// Month and year wheels for a goal's "by when", with a way to clear it.
private struct MonthYearPicker: View {
    @Binding var month: Date?
    @Environment(\.dismiss) private var dismiss
    @State private var monthIndex: Int
    @State private var year: Int

    private let calendar = Calendar.practices
    private let years: [Int]

    init(month: Binding<Date?>) {
        _month = month
        let cal = Calendar.practices
        let start = month.wrappedValue ?? cal.date(byAdding: .month, value: 6, to: .now) ?? .now
        _monthIndex = State(initialValue: cal.component(.month, from: start) - 1)
        _year = State(initialValue: cal.component(.year, from: start))
        let thisYear = cal.component(.year, from: .now)
        years = Array(thisYear...(thisYear + 15))
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Clear") { month = nil; dismiss() }
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("By when").textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20).with(weight: 500))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("Done") {
                    month = calendar.date(from: DateComponents(year: year, month: monthIndex + 1, day: 1))
                    dismiss()
                }
                .foregroundStyle(Theme.textPrimary)
            }
            .textStyle(Theme.Font.body)
            .frame(minHeight: 44)
            HStack(spacing: 0) {
                Picker("Month", selection: $monthIndex) {
                    ForEach(0..<12, id: \.self) { Text(calendar.monthSymbols[$0]).tag($0) }
                }
                Picker("Year", selection: $year) {
                    ForEach(years, id: \.self) { Text(String($0)).tag($0) }
                }
            }
            .pickerStyle(.wheel)
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 12)
        .preferredColorScheme(.dark)
    }
}

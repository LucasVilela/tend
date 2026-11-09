import SwiftData
import SwiftUI

/// Vision: a two-column board of photos and words to look at and remember. Nothing is tracked.
struct VisionView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \VisionTile.order) private var tiles: [VisionTile]

    @State private var editing = false
    @State private var adding = false
    @State private var editingTile: VisionTile?
    @State private var removing: VisionTile?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, Theme.screenPadding)
                if tiles.isEmpty {
                    emptyState
                        .padding(.horizontal, VisionLayout.boardPadding)
                        .padding(.top, 24)
                } else {
                    board.padding(.top, 24)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .floatingAction(color: Theme.textPrimary, label: "Add to board", visible: !editing) { adding = true }
        .fullScreenCover(isPresented: $adding) { AddToBoardSheet(tile: nil) }
        .fullScreenCover(item: $editingTile) { AddToBoardSheet(tile: $0) }
        .confirmationDialog("Remove this tile from your board?", isPresented: removingBinding, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                if let removing { withAnimation { context.delete(removing); try? context.save() } }
            }
            Button("Keep", role: .cancel) {}
        }
    }

    private var removingBinding: Binding<Bool> {
        Binding(get: { removing != nil }, set: { if !$0 { removing = nil } })
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                ScreenTitle(title: "Vision")
                Text("A page to look at and remember")
                    .textStyle(Theme.Font.secondary)
                    .foregroundStyle(Theme.textTertiary)
            }
            if !tiles.isEmpty {
                Button(editing ? "Done" : "Edit") {
                    withAnimation(.easeInOut(duration: 0.2)) { editing.toggle() }
                }
                .textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20))
                .foregroundStyle(Theme.textSecondary)
                .frame(minWidth: 44, minHeight: 44)
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Board

    private var board: some View {
        let width = max(100, (boardWidth - VisionLayout.boardPadding * 2 - VisionLayout.gap) / 2)
        return HStack(alignment: .top, spacing: VisionLayout.gap) {
            ForEach(0..<2, id: \.self) { column in
                VStack(spacing: VisionLayout.gap) {
                    ForEach(tiles.filter { $0.column == column }) { tile in
                        tileCell(tile, width: width)
                    }
                    // Drop here to move a tile to the end of this column.
                    Color.clear
                        .frame(width: width, height: editing ? 80 : 1)
                        .contentShape(Rectangle())
                        .dropDestination(for: String.self) { ids, _ in
                            move(ids.first, toColumn: column, before: nil)
                        }
                }
                .frame(width: width)
            }
        }
        .padding(.horizontal, VisionLayout.boardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { boardWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, new in boardWidth = new }
            }
        }
    }

    @State private var boardWidth: CGFloat = 390

    @ViewBuilder
    private func tileCell(_ tile: VisionTile, width: CGFloat) -> some View {
        let view = VisionTileView(content: TileContent(tile), width: width)
            .overlay {
                if editing {
                    OrganicShape.card.strokeBorder(Theme.outlineStrong, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
            }
            .overlay(alignment: .topTrailing) {
                if editing {
                    Button { removing = tile } label: {
                        ZStack {
                            OrganicShape.blob.fill(Theme.background.opacity(0.85))
                            IconView(icon: .close, size: 14, lineWidth: 1.6).foregroundStyle(Theme.textPrimary)
                        }
                        .frame(width: 26, height: 26)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove tile")
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(OrganicShape.card)

        if editing {
            view
                .draggable(tile.uid.uuidString) {
                    VisionTileView(content: TileContent(tile), width: width).opacity(0.9)
                }
                .dropDestination(for: String.self) { ids, _ in
                    move(ids.first, toColumn: tile.column, before: tile)
                }
                .accessibilityHint("Drag to reorder")
        } else {
            view
                .onTapGesture { editingTile = tile }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Opens the tile to edit")
        }
    }

    /// Moves the dragged tile into `column`, before `target` (or to the end), then renumbers.
    private func move(_ id: String?, toColumn column: Int, before target: VisionTile?) -> Bool {
        guard let id, let dragged = tiles.first(where: { $0.uid.uuidString == id }), dragged !== target else { return false }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            var destination = tiles.filter { $0.column == column && $0 !== dragged }
            let index = target.flatMap { t in destination.firstIndex { $0 === t } } ?? destination.count
            destination.insert(dragged, at: index)
            dragged.column = column
            for (i, tile) in destination.enumerated() { tile.order = i }
            for (i, tile) in tiles.filter({ $0.column != column }).enumerated() { tile.order = i }
            try? context.save()
        }
        return true
    }

    private var emptyState: some View {
        Button { adding = true } label: {
            VStack(spacing: 6) {
                Text("Add a photo or a few words")
                    .textStyle(Theme.Font.bodyLong.with(size: 15, lineHeight: 20))
                    .foregroundStyle(Theme.textPrimary)
                Text("Goals, a mantra, words for the year: anything you want to keep in view")
                    .textStyle(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(OrganicShape.card.strokeBorder(Theme.outlineStrong, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VisionView()
        .modelContainer(SampleData.previewContainer)
        .preferredColorScheme(.dark)
}

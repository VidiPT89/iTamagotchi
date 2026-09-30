import SwiftData
import SwiftUI

/// The family album of past pets and the journal of the current life.
struct AlbumView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AlbumEntry.endedAt, order: .reverse) private var album: [AlbumEntry]
    @Query(sort: \JournalEntry.date, order: .reverse) private var journal: [JournalEntry]
    @State private var tab = 0

    var body: some View {
        ZStack {
            palette.backdrop
            ScrollView {
                VStack(spacing: 16) {
                    SheetHeader(title: model.t("album.title")) { dismiss() }
                        .padding(.horizontal, -20)
                    PillPicker(options: [(0, model.t("album.journal")), (1, model.t("album.family"))], selection: $tab)
                    if tab == 0 { journalList } else { familyGrid }
                }
                .padding(20)
            }
        }
    }

    /// One chapter per life, the current pet first, newest lines on top.
    private var chapters: [(id: UUID, name: String, entries: [JournalEntry])] {
        var order: [UUID] = []
        var groups: [UUID: [JournalEntry]] = [:]
        for entry in journal {
            if groups[entry.petID] == nil { order.append(entry.petID) }
            groups[entry.petID, default: []].append(entry)
        }
        if let current = order.firstIndex(of: model.pet.id) { order.insert(order.remove(at: current), at: 0) }
        return order.map { id in
            let name = id == model.pet.id ? model.pet.name
                : album.first { $0.petID == id }?.name ?? groups[id]?.first?.arguments.first ?? ""
            return (id, name, groups[id] ?? [])
        }
    }

    private var journalList: some View {
        VStack(alignment: .leading, spacing: 22) {
            if journal.isEmpty { empty("album.emptyJournal", symbol: "book") }
            ForEach(chapters, id: \.id) { chapter in
                VStack(alignment: .leading, spacing: 12) {
                    Label(model.t("album.lifeOf", chapter.name),
                          systemImage: chapter.id == model.pet.id ? "heart.fill" : "moon.stars.fill")
                        .font(.rounded(17, .heavy))
                        .foregroundStyle(palette.primary)
                        .accessibilityAddTraits(.isHeader)
                    timeline(chapter.entries)
                }
            }
        }
        .transition(.opacity)
    }

    private func timeline(_ entries: [JournalEntry]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Image(systemName: entry.symbol)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(palette.warmGradient, in: Circle())
                        if index < entries.count - 1 {
                            Rectangle().fill(palette.primary.opacity(0.25)).frame(width: 2).frame(maxHeight: .infinity)
                        }
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.journalText(entry))
                            .font(.rounded(15, .semibold))
                            .foregroundStyle(palette.text)
                        Text(entry.date, format: .dateTime.day().month().hour().minute())
                            .font(.rounded(12, .medium))
                            .foregroundStyle(palette.textDim)
                    }
                    .padding(.bottom, 18)
                    Spacer()
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var familyGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
            if album.isEmpty { empty("album.emptyFamily", symbol: "photo.on.rectangle.angled").gridCellColumns(2) }
            ForEach(album) { entry in
                VStack(spacing: 8) {
                    PetView(stage: entry.stage, form: entry.form, mood: .happy)
                        .frame(height: 110)
                        .background(palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    Text(entry.name).font(.rounded(17, .heavy)).foregroundStyle(palette.text)
                    Text(model.t("album.reached", entry.form.map { model.t("form.\($0.rawValue)") } ?? model.t("stage.\(entry.stage.rawValue)")))
                        .font(.rounded(12, .semibold)).foregroundStyle(palette.primary)
                    Text(model.t("farewell.lived", model.duration(entry.age)))
                        .font(.rounded(12, .medium)).foregroundStyle(palette.textDim)
                    Text(model.t("album.reason.\(entry.reason.rawValue)"))
                        .font(.rounded(11, .medium)).foregroundStyle(palette.textFaint)
                }
                .frame(maxWidth: .infinity)
                .card(padding: 12)
                .accessibilityElement(children: .combine)
            }
        }
        .transition(.opacity)
    }

    private func empty(_ key: String, symbol: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 40)).foregroundStyle(palette.primary.opacity(0.6))
            Text(model.t(key))
                .font(.rounded(15, .medium))
                .foregroundStyle(palette.textDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

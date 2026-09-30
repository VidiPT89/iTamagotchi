import SwiftData
import SwiftUI

/// iPad and landscape companion: detailed needs, the pet's card and the
/// latest journal lines, so the extra space tells you more.
struct SidePanel: View {
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @Query(sort: \JournalEntry.date, order: .reverse) private var journal: [JournalEntry]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 12) {
                    ForEach(NeedKind.allCases) { kind in
                        NeedBar(kind: kind, value: model.pet.needs[kind])
                    }
                }
                .card()

                StatusDetails().card()

                VStack(alignment: .leading, spacing: 10) {
                    Label(model.t("album.journal"), systemImage: "book.closed.fill")
                        .font(.rounded(16, .bold))
                        .foregroundStyle(palette.text)
                    let recent = journal.filter { $0.petID == model.pet.id }.prefix(5)
                    if recent.isEmpty {
                        Text(model.t("album.emptyJournal"))
                            .font(.rounded(13, .regular))
                            .foregroundStyle(palette.textDim)
                    }
                    ForEach(Array(recent)) { entry in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: entry.symbol).foregroundStyle(palette.primary).frame(width: 20)
                            Text(model.journalText(entry))
                                .font(.rounded(13, .medium))
                                .foregroundStyle(palette.text)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
            }
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }
}

struct NeedBar: View {
    let kind: NeedKind
    let value: Double
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette

    var body: some View {
        let color = kind == .discipline ? palette.accent : palette.needColor(value)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: kind.symbol).foregroundStyle(color).frame(width: 20)
                Text(model.t("need.\(kind.rawValue)")).font(.rounded(14, .semibold)).foregroundStyle(palette.text)
                Spacer()
                Text("\(Int(value))").font(.rounded(14, .bold)).monospacedDigit().foregroundStyle(palette.textDim)
                    .contentTransition(.numericText(value: value))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(palette.text.opacity(0.08))
                    Capsule().fill(LinearGradient(colors: [color.opacity(0.7), color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * value / 100))
                }
            }
            .frame(height: 8)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(model.t("a11y.need", model.t("need.\(kind.rawValue)"), Int(value))))
    }
}

/// Age, weight, form and upbringing at a glance.
struct StatusDetails: View {
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette

    var body: some View {
        let pet = model.pet
        VStack(alignment: .leading, spacing: 10) {
            row("status.age", model.duration(pet.age), "clock.fill")
            row("status.stage", model.t("stage.\(pet.stage.rawValue)"), "leaf.fill")
            row("status.form", pet.form.map { model.t("form.\($0.rawValue)") } ?? model.t("status.unknownForm"), "sparkles")
            row("status.weight", model.t("status.weightValue", Int(pet.upbringing.weight)), "scalemass.fill")
            row("status.mistakes", "\(pet.upbringing.careMistakes)", "exclamationmark.triangle.fill")
            row("need.discipline", "\(Int(pet.needs.discipline))", "star.fill")
            if let form = pet.form {
                Text(model.t("form.\(form.rawValue).trait"))
                    .font(.rounded(13, .medium))
                    .foregroundStyle(palette.textDim)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ key: String, _ value: String, _ symbol: String) -> some View {
        HStack {
            Image(systemName: symbol).foregroundStyle(palette.primary).frame(width: 22)
            Text(model.t(key)).font(.rounded(14, .medium)).foregroundStyle(palette.textDim)
            Spacer()
            Text(value).font(.rounded(15, .bold)).foregroundStyle(palette.text)
        }
        .accessibilityElement(children: .combine)
    }
}

struct StatusCardView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let pet = model.pet
        ZStack {
            palette.backdrop
            ScrollView {
                VStack(spacing: 8) {
                    SheetHeader(title: model.t("status.title")) { dismiss() }
                    HStack(spacing: 16) {
                        PetView(stage: pet.stage, form: pet.form, mood: pet.mood, hat: model.household.hat)
                            .frame(width: 110, height: 110)
                            .background(palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pet.name).font(.rounded(26, .heavy)).foregroundStyle(palette.text)
                            Text(model.t("mood.\(pet.mood.rawValue)"))
                                .font(.rounded(15, .semibold)).foregroundStyle(palette.primary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    StatusDetails().card().padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

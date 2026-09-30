import SwiftUI

struct StatsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @State private var tab = 0

    var body: some View {
        ZStack {
            palette.backdrop
            ScrollView {
                VStack(spacing: 16) {
                    SheetHeader(title: model.t("stats.title")) { dismiss() }
                        .padding(.horizontal, -20)
                    PillPicker(options: [(0, model.t("stats.tabStats")), (1, model.t("stats.tabAchievements"))], selection: $tab)
                    if tab == 0 { statsGrid } else { achievements }
                }
                .padding(20)
            }
        }
    }

    private var statsGrid: some View {
        let s = model.stats
        let items: [(String, String, String)] = [
            ("stats.petsRaised", "\(s.petsRaised)", "oval.portrait.fill"),
            ("stats.longestLife", model.duration(max(s.longestLife, model.pet.age)), "hourglass"),
            ("stats.meals", "\(s.meals)", "fork.knife"),
            ("stats.snacks", "\(s.snacks)", "birthday.cake.fill"),
            ("stats.baths", "\(s.baths)", "shower.fill"),
            ("stats.cleanings", "\(s.cleanings)", "wind"),
            ("stats.medicines", "\(s.medicines)", "pills.fill"),
            ("stats.caresses", "\(s.caresses)", "heart.fill"),
            ("stats.gamesPlayed", "\(s.gamesPlayed)", "gamecontroller.fill"),
            ("stats.gamesWon", "\(s.gamesWon)", "trophy.fill"),
            ("stats.coinsEarned", "\(s.coinsEarned)", "dollarsign.circle.fill"),
        ]
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: item.2).font(.system(size: 18, weight: .bold)).foregroundStyle(palette.primary)
                    Text(item.1).font(.rounded(24, .heavy)).foregroundStyle(palette.text).minimumScaleFactor(0.6).lineLimit(1)
                    Text(model.t(item.0)).font(.rounded(13, .medium)).foregroundStyle(palette.textDim)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card(padding: 14)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var achievements: some View {
        let unlocked = model.save.achievements
        return VStack(spacing: 12) {
            Text(model.t("stats.unlocked", unlocked.count, Achievement.allCases.count))
                .font(.rounded(15, .bold))
                .foregroundStyle(palette.primary)
            ForEach(Achievement.allCases) { achievement in
                let done = unlocked[achievement.rawValue] != nil
                HStack(spacing: 14) {
                    Image(systemName: achievement.symbol)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(done ? .white : palette.textFaint)
                        .frame(width: 48, height: 48)
                        .background(done ? AnyShapeStyle(palette.warmGradient) : AnyShapeStyle(palette.surfaceRaised),
                                    in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.t("ach.\(achievement.rawValue)")).font(.rounded(16, .bold)).foregroundStyle(palette.text)
                        Text(model.t("ach.\(achievement.rawValue).desc")).font(.rounded(13, .medium)).foregroundStyle(palette.textDim)
                    }
                    Spacer()
                    if done { Image(systemName: "checkmark.seal.fill").foregroundStyle(palette.success) }
                }
                .opacity(done ? 1 : 0.7)
                .card(padding: 12)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

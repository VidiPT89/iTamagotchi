import SwiftUI

struct ShopView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    @State private var category: ShopCategory = .hats

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        ZStack {
            palette.backdrop
            ScrollView {
                VStack(spacing: 16) {
                    SheetHeader(title: model.t("shop.title")) { dismiss() }
                        .padding(.horizontal, -20)
                    HStack {
                        preview
                        Spacer()
                        CoinPill(coins: model.household.coins)
                    }
                    PillPicker(options: ShopCategory.allCases.map { ($0, model.t("shop.\($0.rawValue)")) },
                               selection: $category)
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(ShopItem.catalog.filter { $0.category == category }) { item in
                            ItemCard(item: item)
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: category)
                }
                .padding(20)
            }
        }
    }

    private var preview: some View {
        PetView(stage: model.pet.stage, form: model.pet.form, mood: .happy, hat: model.household.hat)
            .frame(width: 96, height: 96)
            .background(palette.surfaceRaised, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .accessibilityHidden(true)
    }
}

private struct ItemCard: View {
    let item: ShopItem
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette

    var body: some View {
        let owned = model.household.owned.contains(item.id)
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(item.category == .wallpapers ? AnyShapeStyle(Color.clear) : AnyShapeStyle(palette.surfaceRaised))
                if item.category == .wallpapers {
                    WallpaperView(id: item.id)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    Image(systemName: item.symbol)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(palette.warmGradient)
                }
            }
            .frame(height: 86)

            Text(model.t("item.\(item.id)"))
                .font(.rounded(15, .bold))
                .foregroundStyle(palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            button(owned: owned)
        }
        .card(padding: 12)
    }

    @ViewBuilder
    private func button(owned: Bool) -> some View {
        let household = model.household
        if !owned {
            Button { model.buy(item) } label: {
                HStack(spacing: 4) {
                    Text("¢").font(.rounded(14, .heavy))
                    Text(item.price == 0 ? model.t("shop.free") : "\(item.price)").font(.rounded(15, .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(household.coins >= item.price ? AnyShapeStyle(palette.warmGradient) : AnyShapeStyle(palette.textFaint),
                            in: Capsule())
            }
            .buttonStyle(.pressable)
        } else {
            let active = item.category == .hats ? household.hat == item.id
                : item.category == .wallpapers ? household.wallpaper == item.id : true
            Button {
                switch item.category {
                case .hats: model.wear(active ? nil : item.id)
                case .wallpapers: model.applyWallpaper(item.id)
                case .decor: break
                }
            } label: {
                Text(label(active: active))
                    .font(.rounded(14, .bold))
                    .foregroundStyle(active ? palette.success : palette.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background((active ? palette.success : palette.primary).opacity(0.14), in: Capsule())
            }
            .buttonStyle(.pressable)
            .disabled(item.category == .decor)
        }
    }

    private func label(active: Bool) -> String {
        switch item.category {
        case .hats: return model.t(active ? "shop.remove" : "shop.wear")
        case .wallpapers: return model.t(active ? "shop.applied" : "shop.apply")
        case .decor: return model.t("shop.owned")
        }
    }
}

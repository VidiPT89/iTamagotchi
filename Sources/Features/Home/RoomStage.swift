import SpriteKit
import SwiftUI

/// The interactive room: swipe between rooms, tap to cuddle, hold for the
/// status card, and the pet's eyes follow the finger. Food can be dragged
/// from the tray onto the pet.
struct RoomStage: View {
    @Binding var room: Room
    @Binding var swipeEdge: Edge
    @Binding var feeding: Bool
    @Binding var showStatus: Bool

    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var petX: CGFloat = 0.5
    @State private var walking = false
    @State private var direction: CGFloat = 1
    @State private var gaze: CGPoint?
    @State private var holdTask: Task<Void, Never>?
    @State private var holdFired = false
    @State private var dragFood: Food?
    @State private var dragPoint: CGPoint = .zero
    @State private var shelf: FoodGroup = .meals

    /// Where the pet is right now: on the floor, tucked in bed or in the tub.
    enum Spot: Equatable { case floor, bed, tub }

    private var spot: Spot {
        let pet = model.pet
        if room == .bathroom, model.bathing { return .tub }
        if room == .bedroom, pet.isAsleep, pet.isAlive { return .bed }
        return .floor
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let floorPetSize = min(size.width * 0.62, size.height * 0.66)
            let floorY = size.height * 0.94
            let spot = spot
            let pet = model.pet
            let look = PetAppearance.of(stage: pet.stage, form: pet.form)
            let petFrame = Self.petFrame(spot: spot, size: size, floorPetSize: floorPetSize, floorY: floorY,
                                         petX: petX, scale: look.scale)
            let petSize = petFrame.width

            ZStack(alignment: .topLeading) {
                RoomBackdrop(room: room, wallpaper: model.household.wallpaper,
                             decor: model.household.decor(in: room), clock: pet.simClock, lightsOn: pet.lightsOn)
                    .id(room)
                    .transition(.push(from: swipeEdge))

                poops(size: size, floorY: floorY)

                PetView(stage: pet.stage, form: pet.form, mood: pet.mood, hat: model.household.hat,
                        reaction: model.reaction, gaze: gaze.map { CGPoint(x: $0.x - petFrame.minX, y: $0.y - petFrame.minY) },
                        walking: walking && spot == .floor, direction: direction, shadow: spot == .floor)
                    .frame(width: petSize, height: petSize)
                    .position(x: petFrame.midX, y: petFrame.midY)
                    .brightness(pet.lightsOn ? 0 : -0.25)
                    .accessibilityElement()
                    .accessibilityLabel(Text(model.t("a11y.pet", pet.name, model.t("stage.\(pet.stage.rawValue)"),
                                                     model.t("mood.\(pet.mood.rawValue)"))))
                    .accessibilityHint(Text(model.t("a11y.petHint")))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { model.perform(.caress) }
                    .accessibilityAction(named: Text(model.t("status.title"))) { showStatus = true }

                // Bedding and the side of the tub go in front of the pet.
                Group {
                    if spot == .bed {
                        Duvet(top: petFrame.minY + petSize * (0.9 - look.scale * 0.45))
                    } else if spot == .tub {
                        TubFront(foam: true)
                    }
                }
                .brightness(pet.lightsOn ? 0 : -0.3)
                .transition(.opacity)

                if let wish = Self.wish(for: pet), model.reaction.map({ $0.until < Date() }) ?? true {
                    ThoughtBubble(symbol: wish)
                        .position(x: min(petFrame.maxX - petSize * 0.12, size.width - 34),
                                  y: petFrame.minY + petSize * (1 - look.scale) * 0.55)
                        .transition(.scale(scale: 0.3, anchor: .bottomLeading).combined(with: .opacity))
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }

                SpriteView(scene: model.effects, options: [.allowsTransparency])
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                if feeding { foodTray(size: size, petFrame: petFrame) }

                if let dragFood {
                    Text(dragFood.emoji)
                        .font(.system(size: 52))
                        .position(dragPoint)
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(name: "stage")
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: Self.wish(for: pet))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: spot)
            .contentShape(Rectangle())
            .gesture(stageGesture(petFrame: petFrame))
            .onAppear { updateAnchor(petFrame) }
            .onChange(of: petFrame) { _, frame in updateAnchor(frame) }
            .onChange(of: size) { _, _ in model.effects.size = size }
            .onAppear { model.effects.size = size; model.effects.reduceMotion = reduceMotion }
            #if DEBUG
            .onAppear { if let qaShelf = AppModel.qaShelf { shelf = qaShelf } }
            #endif
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(palette.stroke, lineWidth: 1))
        .shadow(color: .black.opacity(palette.isDark ? 0.4 : 0.1), radius: 18, y: 8)
        .task(id: model.pet.mood) { await wander() }
        .onDisappear {
            holdTask?.cancel()
            holdTask = nil
            holdFired = false
            gaze = nil
        }
        .onChange(of: reduceMotion) { _, value in model.effects.reduceMotion = value }
    }

    /// What the pet is asking for, most pressing first, shown in its bubble.
    nonisolated static func wish(for pet: PetState) -> String? {
        guard pet.isAlive, pet.stage != .egg else { return nil }
        if pet.isAsleep { return pet.lightsOn ? "lightbulb.fill" : nil }
        if pet.isSick { return "pills.fill" }
        if pet.isTantrum { return "exclamationmark" }
        if pet.needs.hunger < 25 { return "fork.knife" }
        if pet.poops >= 2 { return "wind" }
        if pet.needs.energy < 20 { return "moon.zzz.fill" }
        if pet.needs.happiness < 25 { return "gamecontroller.fill" }
        if pet.needs.hygiene < 25 { return "bathtub.fill" }
        return nil
    }

    private func updateAnchor(_ frame: CGRect) {
        model.petAnchor = CGPoint(x: frame.midX, y: frame.maxY - frame.height * 0.5)
    }

    /// The pet's canvas. Its body stands on 90% of the canvas height, so the
    /// bottom of the body is placed on the floor, the mattress or the water.
    static func petFrame(spot: Spot, size: CGSize, floorPetSize: CGFloat, floorY: CGFloat,
                         petX: CGFloat, scale: CGFloat) -> CGRect {
        switch spot {
        case .floor:
            return CGRect(x: size.width * petX - floorPetSize / 2, y: floorY - floorPetSize,
                          width: floorPetSize, height: floorPetSize)
        case .bed:
            let side = floorPetSize * 0.72
            let bottom = size.height * RoomLayout.mattressTop + side * scale * 0.25
            return CGRect(x: size.width * RoomLayout.bedPetX - side / 2, y: bottom - side * 0.9, width: side, height: side)
        case .tub:
            let side = floorPetSize * 0.82
            let bottom = size.height * RoomLayout.tub.minY + side * scale * 0.28
            return CGRect(x: size.width * RoomLayout.tubPetX - side / 2, y: bottom - side * 0.9, width: side, height: side)
        }
    }

    // MARK: Poops

    private func poops(size: CGSize, floorY: CGFloat) -> some View {
        let spots: [CGFloat] = [0.14, 0.86, 0.26, 0.74]
        return ForEach(0..<model.pet.poops, id: \.self) { i in
            PoopView()
                .frame(width: 44, height: 44)
                .position(x: size.width * spots[i % spots.count], y: floorY - 22)
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel(Text(model.t("a11y.poop")))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: model.pet.poops)
    }

    // MARK: Food tray

    private func foodTray(size: CGSize, petFrame: CGRect) -> some View {
        let tile = min(size.width > 600 ? 100 : 72, (size.width - 64) / 4)
        let favorite = model.pet.favoriteFood
        return VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(FoodGroup.allCases) { group in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { shelf = group }
                        model.audio.play(.tap)
                    } label: {
                        Text(model.t("foodGroup.\(group.rawValue)"))
                            .font(.rounded(12, .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(shelf == group ? .white : Color(hex: 0x5A3A1E))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(shelf == group ? AnyShapeStyle(Color(hex: 0xDD7400)) : AnyShapeStyle(.white.opacity(0.7)),
                                        in: Capsule())
                    }
                    .buttonStyle(.pressable)
                    .accessibilityAddTraits(shelf == group ? .isSelected : [])
                }
            }
            HStack(spacing: 8) {
                ForEach(shelf.foods) { food in
                    VStack(spacing: 2) {
                        Text(food.emoji).font(.system(size: tile * 0.46))
                        Text(model.t("food.\(food.rawValue)"))
                            .font(.rounded(10, .bold))
                            .foregroundStyle(Color(hex: 0x3A2A1A))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .padding(.horizontal, 3)
                    }
                    .frame(width: tile, height: tile)
                    .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        if food == favorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: 0xE5484D))
                                .padding(5)
                        }
                    }
                    .opacity(dragFood == food ? 0.35 : 1)
                    .gesture(foodGesture(food, petFrame: petFrame))
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { feed(food) }
                }
            }
            .id(shelf)
            .transition(.opacity)
            Text(model.t("food.groupHint.\(shelf.rawValue)") + " · " + model.t("action.feedHint"))
                .font(.rounded(11, .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(.black.opacity(0.35), in: Capsule())
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .environment(\.colorScheme, .light)
        .frame(maxWidth: size.width - 24)
        // Below the room label, clear of the pet.
        .position(x: size.width / 2, y: 50 + (tile + 100) / 2)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func foodGesture(_ food: Food, petFrame: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("stage"))
            .onChanged { value in
                dragFood = food
                dragPoint = value.location
                gaze = value.location
            }
            .onEnded { value in
                let moved = hypot(value.translation.width, value.translation.height)
                if moved < 8 || petFrame.insetBy(dx: -20, dy: -20).contains(value.location) { feed(food) }
                dragFood = nil
                gaze = nil
            }
    }

    private func feed(_ food: Food) {
        model.perform(.feed(food))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { feeding = false }
    }

    // MARK: Gestures

    private func stageGesture(petFrame: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                gaze = value.location
                let moved = hypot(value.translation.width, value.translation.height)
                if moved > 12 {
                    holdTask?.cancel()
                } else if holdTask == nil, !holdFired, petFrame.contains(value.startLocation) {
                    // Press and hold opens the status card while the finger is still down.
                    holdTask = Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.5))
                        guard !Task.isCancelled else { return }
                        holdFired = true
                        model.haptics.play(.soft)
                        showStatus = true
                    }
                }
            }
            .onEnded { value in
                let held = holdFired
                holdTask?.cancel()
                holdTask = nil
                holdFired = false
                gaze = nil
                guard !held else { return }
                let dx = value.translation.width
                let dy = value.translation.height
                if abs(dx) > 60, abs(dx) > abs(dy) * 1.4 {
                    switchRoom(forward: dx < 0)
                    return
                }
                guard hypot(dx, dy) < 12, petFrame.contains(value.startLocation) else { return }
                model.perform(.caress)
            }
    }

    private func switchRoom(forward: Bool) {
        let all = Room.allCases
        guard let index = all.firstIndex(of: room) else { return }
        let next = forward ? index + 1 : index - 1
        guard all.indices.contains(next) else {
            model.haptics.play(.soft)
            return
        }
        swipeEdge = forward ? .trailing : .leading
        model.audio.play(.tap)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { room = all[next] }
    }

    // MARK: Wandering

    private func wander() async {
        while !Task.isCancelled {
            let pause = Double.random(in: 3.5...7)
            try? await Task.sleep(for: .seconds(pause))
            guard !Task.isCancelled else { return }
            let pet = model.pet
            guard !reduceMotion, !pet.isAsleep, pet.mood.liveliness >= 0.35,
                  model.reaction.map({ $0.until < Date() }) ?? true, !feeding
            else { continue }
            let target = CGFloat.random(in: 0.3...0.7)
            let distance = abs(target - petX)
            guard distance > 0.06 else { continue }
            let duration = Double(distance) * 5
            direction = target > petX ? 1 : -1
            walking = true
            withAnimation(.easeInOut(duration: duration)) { petX = target }
            try? await Task.sleep(for: .seconds(duration))
            walking = false
        }
    }
}

/// A little thought cloud with the thing the pet wants inside.
private struct ThoughtBubble: View {
    let symbol: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Circle().fill(.white).frame(width: 9, height: 9).offset(x: -10, y: 14)
            Circle().fill(.white).frame(width: 14, height: 14).offset(x: -2, y: 6)
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: 0xDD7400))
                .symbolEffect(.pulse, isActive: !reduceMotion)
                .frame(width: 48, height: 44)
                .background(.white, in: Capsule())
                .offset(x: 6, y: -6)
        }
        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        .offset(y: bob ? -4 : 2)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { bob = true }
        }
    }
}

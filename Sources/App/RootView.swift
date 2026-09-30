import SwiftData
import SwiftUI

/// Splash first, then onboarding or the home screen, with the big moments
/// (evolution, farewell) and toasts layered on top.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.palette) private var palette
    @State private var showSplash = true

    init() {
        #if DEBUG
        _showSplash = State(initialValue: !AppModel.qaSkipSplash)
        #endif
    }

    var body: some View {
        @Bindable var model = model
        ZStack {
            palette.backdrop

            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.7)) { showSplash = false }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.04)))
                .zIndex(3)
            } else if !model.save.hasOnboarded || model.pet.stage == .egg {
                OnboardingView(askLanguage: !model.save.hasOnboarded)
                    .transition(.opacity)
            } else {
                HomeView()
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }

            if !showSplash, !model.pet.isAlive {
                FarewellView()
                    .transition(.opacity)
                    .zIndex(2)
            }

            if !showSplash, let stage = model.evolvedTo {
                EvolutionView(stage: stage)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .overlay(alignment: .top) {
            if let toast = model.toast, !showSplash {
                ToastView(toast: toast)
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(5)
                    .allowsHitTesting(false)
            }
        }
        .sheet(item: showSplash ? .constant(nil) : $model.awaySummary) { summary in
            AwaySummaryView(summary: summary)
                .themed()
                .environment(model)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            model.attach(context)
            switch phase {
            case .active: model.sceneBecameActive()
            case .background: model.sceneWentToBackground()
            default: break
            }
        }
    }
}

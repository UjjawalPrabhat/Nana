import SwiftData
import SwiftUI

/// Welcome → pair the Pod → two permissions → Home.
/// Every step after Welcome can be skipped and done later from Settings.
struct OnboardingFlow: View {
    var onFinish: () -> Void

    @State private var path = Self.initialPath

    enum Step: Int {
        case pair = 2, permissions
    }

    static let stepCount = Step.permissions.rawValue

    // Debug builds accept `-NanaOnboardingStep 2…3` for screenshots and UI tests.
    private static var initialPath: [Step] {
        #if DEBUG
        let step = UserDefaults.standard.integer(forKey: "NanaOnboardingStep")
        return (Step.pair.rawValue...Step.permissions.rawValue).filter { $0 <= step }.compactMap(Step.init)
        #else
        []
        #endif
    }

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView { path.append(.pair) }
                .navigationDestination(for: Step.self) { step in
                    Group {
                        switch step {
                        case .pair: PairStepView { path.append(.permissions) }
                        case .permissions: PermissionsView(onFinish: onFinish)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .nanaBackButton()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            StepCounter(step: step.rawValue, total: Self.stepCount)
                        }
                        .sharedBackgroundVisibility(.hidden)
                    }
                }
        }
    }
}

struct WelcomeView: View {
    var onStart: () -> Void

    @State private var showsPrivacy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Wordmark()
                Spacer()
                StepCounter(step: 1, total: OnboardingFlow.stepCount)
            }

            ZStack {
                Circle().fill(.banana).frame(width: 250, height: 250).offset(x: 10, y: 36)
                PodView(count: 3, scale: 0.9)
                    .rotationEffect(.degrees(-7))
                    .offset(y: 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)

            Text("Care,\nkept close.")
                .font(.nanaDisplay)
                .lineHeight(.multiple(factor: 0.86))
                .foregroundStyle(.cobalt)
                .accessibilityAddTraits(.isHeader)
            Text("Nana counts what is in your Pod and gives you a quiet nudge before you run out.")
                .font(.nana(.text, size: 18))
                .padding(.top, 24)
                .padding(.bottom, 26)

            Button("Get started", action: onStart)
                .nanaPrimaryButton()

            HStack(spacing: 4) {
                Text("Setup takes about a minute.")
                Button("How Nana handles your data") { showsPrivacy = true }
                    .fontWeight(.bold)
                    .underline()
            }
            .font(.nanaFootnote)
            .foregroundStyle(.inkSoft)
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .scrollsAtAccessibilitySizes()
        .nanaScreen()
        .toolbarVisibility(.hidden, for: .navigationBar)
        .sheet(isPresented: $showsPrivacy) {
            NavigationStack {
                PrivacyPolicyView()
                    .nanaCloseButton { showsPrivacy = false }
            }
        }
    }
}

#if DEBUG
#Preview {
    OnboardingFlow(onFinish: {})
        .modelContainer(for: SupplyEvent.self, inMemory: true)
        .environment(ContainerStore.preview(paired: false))
        .environment(AppRouter())
        .environment(LeftBehindNudge(scheduler: SilentNudgeScheduler()))
}
#endif

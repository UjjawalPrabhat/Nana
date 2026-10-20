import SwiftData
import SwiftUI

/// Welcome → 18+ check → (set up: starting count) → app.
/// "Explore first" skips setup; everything can be done later from Home and Settings.
struct OnboardingFlow: View {
    var onFinish: () -> Void

    @State private var path: [Step] = []

    enum Step: Hashable {
        case ageCheck(thenSetUp: Bool)
        case pair
        case startingCount
        case underage
    }

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onSetUp: { path.append(.ageCheck(thenSetUp: true)) },
                onExplore: { path.append(.ageCheck(thenSetUp: false)) }
            )
            .navigationDestination(for: Step.self) { step in
                switch step {
                case .ageCheck(let thenSetUp):
                    AgeCheckView {
                        if thenSetUp { path.append(.pair) } else { onFinish() }
                    } onUnderage: {
                        path.append(.underage)
                    }
                case .pair:
                    // A paired container reports the count itself, so skip asking for it.
                    PairContainerView { paired in
                        if paired { onFinish() } else { path.append(.startingCount) }
                    }
                case .startingCount:
                    StartingCountView(onDone: onFinish)
                case .underage:
                    UnderageView()
                }
            }
        }
    }
}

struct WelcomeView: View {
    var onSetUp: () -> Void
    var onExplore: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppMark()
                    .padding(.top, 24)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Care, kept close.")
                        .font(.largeTitle.bold())
                    Text("Keep track of your supply and learn something useful, one minute at a time.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
                .foregroundStyle(Color.textPrimary)

                ContainerIllustration()
                    .frame(height: 220)

                Label {
                    Text("Everything stays on this iPhone. Reminders stay off until you choose them.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textPrimary)
                } icon: {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(Color.brandGreen)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.surface, in: .rect(cornerRadius: 18))
                .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(Color.hairline) }
            }
            .padding(.horizontal, 20)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button(action: onSetUp) {
                    Text("Set up Nana").frame(maxWidth: .infinity)
                }
                .nanaPrimaryButton()

                Button("Explore first", action: onExplore)
                    .font(.body.weight(.semibold))
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .nanaCanvas()
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}

struct AgeCheckView: View {
    var onAdult: () -> Void
    var onUnderage: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nana is for adults")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.textPrimary)
            Text("Nana talks openly about sexual health. Please confirm you are 18 or older to continue.")
                .foregroundStyle(Color.textSecondary)
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button(action: onAdult) {
                    Text("I'm 18 or older").frame(maxWidth: .infinity)
                }
                .nanaPrimaryButton()

                Button("I'm under 18", action: onUnderage)
                    .font(.body.weight(.semibold))
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .nanaCanvas()
    }
}

struct UnderageView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Thanks for being honest")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.textPrimary)
            Text("Nana is made for adults, so it isn't available for you yet. If you have questions about your health, a doctor, nurse, or your local Puskesmas can help in private.")
                .foregroundStyle(Color.textSecondary)
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .nanaCanvas()
        .navigationBarBackButtonHidden()
    }
}

struct StartingCountView: View {
    var onDone: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var count = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How many do you have right now?")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.textPrimary)
            Text("Nana uses this as your starting count. You can change it any time.")
                .foregroundStyle(Color.textSecondary)
            CountStepper(value: $count, range: 0...SupplyLedger.capacity, accessibilityLabel: "Starting count")
                .padding(.top, 8)
            Spacer()
        }
        .padding(20)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button {
                    modelContext.insert(SupplyEvent(kind: .adjust, amount: count))
                    onDone()
                } label: {
                    Text("Save and continue").frame(maxWidth: .infinity)
                }
                .nanaPrimaryButton()

                Button("Skip for now", action: onDone)
                    .font(.body.weight(.semibold))
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .nanaCanvas()
    }
}

#Preview {
    OnboardingFlow(onFinish: {})
        .modelContainer(for: SupplyEvent.self, inMemory: true)
        .environment(ContainerStore.preview(paired: false))
}

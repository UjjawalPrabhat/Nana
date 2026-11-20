import SwiftData
import SwiftUI

nonisolated enum PartnerInfo {
    /// Where privacy questions and support requests go.
    static let contactEmail = "hey@keepnana.com"
    static let contactURL = URL(string: "mailto:hey@keepnana.com")!
    static let website = URL(string: "https://keepnana.com")!
    /// The public copy of the privacy policy, also given to App Store Connect.
    static let privacyPolicyURL = URL(string: "https://keepnana.com/privacy")!
    static let policyUpdated = DateComponents(calendar: .current, year: 2026, month: 10, day: 26).date!
}

/// A page of outlined cards with a big title, shared by Privacy and Health.
private struct InfoPage<Content: View>: View {
    var title: LocalizedStringKey
    var intro: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .nanaScreenTitle()
                    .padding(.bottom, 8)
                Text(intro)
                    .font(.nana(.text, size: 16))
                    .padding(.bottom, 6)
                content
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .nanaScreen()
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct InfoCard<Content: View>: View {
    var title: LocalizedStringKey
    var systemImage: String?
    var tile: Color = .banana
    var fill: Color = .card
    var foreground: Color = .nightInk
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if let systemImage { IconTile(systemImage: systemImage, fill: tile, size: 34) }
                Text(title)
                    .font(.nanaCardTitle)
                    .accessibilityAddTraits(.isHeader)
            }
            content.font(.nanaCallout)
        }
        .foregroundStyle(foreground)
        .nanaCard(fill, padding: 18)
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ContainerStore.self) private var containerStore
    @Environment(AppRouter.self) private var router
    @State private var confirmsDelete = false
    @State private var isDeleting = false
    @State private var deleteFailure: AppReset.Failure?

    var body: some View {
        InfoPage(title: "Your privacy,\nin plain words", intro: "Nana keeps a count, not a diary. Here is everything it touches.") {
            InfoCard(title: "Stays on this phone", systemImage: "iphone") {
                Text("How many condoms are in your charm right now and when that last changed, when your charm last went out of range, your charm's pairing ID and your settings. Only the current count is kept, never a history. Like the rest of your phone, it's included in your iPhone backup if you use one.")
            }
            InfoCard(title: "Never asked, never stored", systemImage: "nosign", tile: .tangerine, fill: .cobalt, foreground: .butter) {
                Text("Your sex life, partners, health status, test results, contacts or photos. A count going down only means a condom left the charm. Nana never guesses why.")
            }
            InfoCard(title: "Leaves your phone", systemImage: "arrow.up.right", tile: .lilac) {
                Text("Nothing by default. No account, no ads, no tracking, no analytics. If this changes, Nana asks you first and tells you what and why.")
            }
            InfoCard(title: "On your lock screen", systemImage: "bell", tile: .butter) {
                Text("A nudge says what happened, like “Your charm stayed behind”, but never what's in your charm. Turn on Discreet notifications in Settings and every nudge only says “You have a reminder.”")
            }
            InfoCard(title: "Your controls") {
                Text("Turn off notifications any time in Settings. Delete everything and Nana forgets your charm and your history on this phone.")
                Button("Delete everything") { confirmsDelete = true }
                    .nanaSecondaryButton()
                    .disabled(isDeleting)
                    .padding(.top, 4)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("The fine print").font(.nanaLabel)
                Group {
                    Text("Written to follow Indonesia's Personal Data Protection Law (UU PDP) and the App Store privacy rules.")
                    HStack(spacing: 4) {
                        Text("Questions:")
                        Link(PartnerInfo.contactEmail, destination: PartnerInfo.contactURL).bold()
                    }
                    Link("Read it on keepnana.com", destination: PartnerInfo.privacyPolicyURL).bold()
                    Text("Last updated \(PartnerInfo.policyUpdated, format: .dateTime.day().month(.wide).year()).")
                }
                .font(.nanaFootnote)
            }
            .nanaCard(.lilac, padding: 18)
        }
        .confirmationDialog("Delete everything?", isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { Task { await eraseAll() } }
        } message: {
            Text("Nana forgets your charm and your count on this phone. This can't be undone.")
        }
        .alert(
            "Couldn't delete everything",
            isPresented: Binding { deleteFailure != nil } set: { if !$0 { deleteFailure = nil } },
            presenting: deleteFailure
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { failure in
            switch failure {
            case .history: Text("Your charm was unpaired, but your count history couldn't be deleted. Try again.")
            case .unpair: Text("Your charm couldn't be unpaired, so nothing was deleted. Try again.")
            }
        }
    }

    private func eraseAll() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await AppReset.eraseAll(modelContext: modelContext, containerStore: containerStore, router: router)
        } catch {
            deleteFailure = error
        }
    }
}

struct HealthSafetyView: View {
    var body: some View {
        InfoPage(title: "Health\nand safety", intro: "Nana is not medical advice. For anything about your body or your status, talk to a clinic or pharmacist.") {
            InfoCard(title: "If a condom breaks or slips", fill: .tangerine) {
                Text("Two things can't wait. HIV PEP has to start within 72 hours, and sooner works better. Emergency contraception also works best the sooner you take it. Go to a clinic, pharmacy or doctor today.")
            }
            InfoCard(title: "Get tested") {
                Text("A test is the only way to know your HIV and STI status. Testing is confidential.")
            }
            InfoCard(title: "Latex sensitivity") {
                Text("If latex makes your skin itch or burn, switch to non-latex condoms made of polyurethane or polyisoprene, and see a doctor.")
            }
            InfoCard(title: "Keep them cool", fill: .lilac) {
                Text("Heat and sharp objects damage condoms. Don't leave your charm on a motorbike seat in the sun or in a hot car. Skip any condom past its date or with a torn wrapper.")
            }
            Link(destination: URL(string: "tel:119")!) {
                HStack(spacing: 14) {
                    Text(verbatim: "119")
                        .font(.nana(.condensedExtraBold, size: 44, relativeTo: .largeTitle))
                    Text("\(Text("Medical emergency in Indonesia.").bold()) Call for an ambulance or urgent medical help. 112 also works for any emergency.")
                        .font(.nanaCallout)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(.butter)
                .nanaCard(.cobalt, padding: 18)
            }
            .accessibilityLabel("Call 119, medical emergency in Indonesia")
            InfoCard(title: "Where this comes from", fill: .lilac) {
                Text("Based on World Health Organization guidance on condom use, HIV post-exposure prophylaxis (PEP) and emergency contraception, and on Indonesia's Ministry of Health (Kemenkes) guidance. Rules and medicines can differ by country; a clinic or pharmacist can tell you what applies to you.")
            }
        }
    }
}

#if DEBUG
#Preview("Privacy") {
    NavigationStack { PrivacyPolicyView() }
        .modelContainer(for: SupplyEvent.self, inMemory: true)
        .environment(ContainerStore.preview())
        .environment(AppRouter())
}

#Preview("Health") {
    NavigationStack { HealthSafetyView() }
}
#endif

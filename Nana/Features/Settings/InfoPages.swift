import SwiftData
import SwiftUI

/// Details still to confirm with partners. Lines that use them stay hidden
/// until they're filled in.
nonisolated enum PartnerInfo {
    /// Partner testing clinic, to confirm with Yayasan Kerti Praja.
    static let clinic: String? = nil
    /// Where privacy questions go.
    static let contactEmail: String? = nil
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
                    .font(.nanaTitle)
                    .lineHeight(.multiple(factor: 0.9))
                    .foregroundStyle(.cobalt)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, 8)
                Text(intro)
                    .font(.custom("AtkinsonHyperlegibleNext-Regular", size: 16, relativeTo: .body))
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
    @State private var confirmsDelete = false
    @State private var isDeleted = false

    var body: some View {
        InfoPage(title: "Your privacy,\nin plain words", intro: "Nana keeps a count, not a diary. Here is everything it touches.") {
            InfoCard(title: "Stays on this phone", systemImage: "iphone") {
                Text("How many condoms your charm holds, when the count last changed, your charm's pairing ID, and the places you pinned.")
            }
            InfoCard(title: "Never asked, never stored", systemImage: "nosign", tile: .tangerine, fill: .cobalt, foreground: .butter) {
                Text("Your sex life, partners, health status, test results, contacts or photos. A count going down only means a condom left the charm. Nana never guesses why.")
            }
            InfoCard(title: "Leaves your phone", systemImage: "arrow.up.right", tile: .lilac) {
                Text("Nothing by default. No account, no ads, no tracking, no analytics. If this changes, Nana asks you first and tells you what and why.")
            }
            InfoCard(title: "On your lock screen", systemImage: "bell", tile: .butter) {
                Text("Every nudge says “Your reminder is ready.” No product names, no counts, no hints.")
            }
            InfoCard(title: "Your controls") {
                Text("Turn off location or notifications any time in Settings. Delete everything and Nana forgets your charm, your places and your history on this phone.")
                Button(isDeleted ? "Deleted from this phone" : "Delete everything") { confirmsDelete = true }
                    .buttonStyle(NanaSecondaryButtonStyle(stroke: .nightInk, fill: .card))
                    .disabled(isDeleted)
                    .padding(.top, 4)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("The fine print").font(.nanaLabel)
                Group {
                    Text("Written to follow Indonesia's Personal Data Protection Law (UU PDP) and the App Store privacy rules.")
                    if let email = PartnerInfo.contactEmail {
                        Text("Questions: \(email).")
                    }
                    Text("Last updated \(PartnerInfo.policyUpdated, format: .dateTime.day().month(.wide).year()).")
                }
                .font(.nanaFootnote)
            }
            .nanaCard(.lilac, padding: 18)
        }
        .confirmationDialog("Delete everything?", isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive, action: eraseAll)
        } message: {
            Text("Nana forgets your charm, your places and your count on this phone. This can't be undone.")
        }
    }

    private func eraseAll() {
        try? modelContext.delete(model: SupplyEvent.self)
        try? modelContext.delete(model: Place.self)
        try? modelContext.save()
        Task { try? await containerStore.forget() }
        UIApplication.shared.setAlternateIconName(nil)
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        isDeleted = true
        // Clearing `hasOnboarded` returns the app to Welcome.
        UserDefaults.standard.set(false, forKey: AppSettings.hasOnboarded)
    }
}

struct HealthSafetyView: View {
    var body: some View {
        InfoPage(title: "Health\nand safety", intro: "Nana is not medical advice. For anything about your body or your status, talk to a clinic or pharmacist.") {
            InfoCard(title: "If a condom breaks or slips", fill: .tangerine) {
                Text("Two things can't wait. HIV PEP has to start within 72 hours, and sooner works better. Emergency contraception also works best the sooner you take it. Go to a clinic or pharmacy today.")
            }
            InfoCard(title: "Get tested") {
                Text("A test is the only way to know your HIV and STI status. Testing is confidential.")
                if let clinic = PartnerInfo.clinic {
                    Text(clinic)
                        .font(.nanaFootnote)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.butter, in: .rect(cornerRadius: 18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(.cobalt, style: StrokeStyle(lineWidth: 2.5, dash: [6, 4]))
                        }
                }
            }
            InfoCard(title: "Latex sensitivity") {
                Text("If latex makes your skin itch or burn, switch to non-latex condoms made of polyurethane or polyisoprene, and see a doctor.")
            }
            InfoCard(title: "Keep them cool", fill: .lilac) {
                Text("Heat and sharp objects damage condoms. Don't leave your charm on a motorbike seat in the sun or in a hot car. Skip any condom past its date or with a torn wrapper.")
            }
            Link(destination: URL(string: "tel:112")!) {
                HStack(spacing: 14) {
                    Text(verbatim: "112")
                        .font(.custom("BricolageGrotesqueCondensed-ExtraBold", size: 44, relativeTo: .largeTitle))
                    Text("\(Text("Emergency in Indonesia.").bold()) Call for urgent medical help.")
                        .font(.nanaCallout)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(.butter)
                .nanaCard(.cobalt, padding: 18)
            }
            .accessibilityLabel("Call 112, emergency in Indonesia")
        }
    }
}

#if DEBUG
#Preview("Privacy") {
    NavigationStack { PrivacyPolicyView() }
        .modelContainer(for: [SupplyEvent.self, Place.self], inMemory: true)
        .environment(ContainerStore.preview())
}

#Preview("Health") {
    NavigationStack { HealthSafetyView() }
}
#endif

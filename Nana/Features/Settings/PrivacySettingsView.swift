import SwiftData
import SwiftUI

struct PrivacySettingsView: View {
    @AppStorage(AppSettings.appLockOn) private var appLockOn = false
    @AppStorage(AppSettings.showNanaOnHome) private var showNanaOnHome = true
    @Environment(\.modelContext) private var modelContext
    @Environment(ContainerStore.self) private var containerStore
    @State private var confirmErase = false

    var body: some View {
        Form {
            Section {
                Toggle("Require Face ID or passcode", isOn: Binding(
                    get: { appLockOn },
                    set: { newValue in setAppLock(newValue) }
                ))
                .disabled(!AppLock.isAvailable)
            } header: {
                Text("App lock")
            } footer: {
                Text(AppLock.isAvailable
                     ? "Nana locks when you leave it, and is always hidden in the app switcher."
                     : "Set up Face ID or a passcode in iOS Settings to use App Lock.")
            }

            Section {
                Toggle("Show Nana on Home", isOn: $showNanaOnHome)
            } footer: {
                Text("Nana always stays inside the app. It never appears on the Lock Screen, in widgets or on the app icon.")
            }

            Section {
                LabeledContent("Where your data lives", value: String(localized: "This iPhone only"))
                LabeledContent("Accounts and tracking", value: String(localized: "None"))
            } footer: {
                Text("Your count and lesson progress are never uploaded. Quiz answers aren't stored.")
            }

            Section {
                Button("Erase all data", role: .destructive) { confirmErase = true }
            }
        }
        .scrollContentBackground(.hidden)
        .nanaCanvas()
        .navigationTitle("Privacy and data")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Erase all data?", isPresented: $confirmErase, titleVisibility: .visible) {
            Button("Erase everything", role: .destructive) { eraseAll() }
        } message: {
            Text("This removes your count, lesson progress and container pairing from this iPhone. It can't be undone.")
        }
    }

    private func setAppLock(_ isOn: Bool) {
        Task {
            // Confirm it's the owner before changing the lock either way.
            if await AppLock.authenticate() { appLockOn = isOn }
        }
    }

    private func eraseAll() {
        try? modelContext.delete(model: SupplyEvent.self)
        try? modelContext.delete(model: LessonCompletion.self)
        try? modelContext.save()
        Task { try? await containerStore.forget() }
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        // Clearing `hasOnboarded` returns the app to Welcome.
        UserDefaults.standard.set(false, forKey: AppSettings.hasOnboarded)
    }
}

/// About Nana, how lessons were made, and every source.
struct HelpView: View {
    @Environment(\.contentLibrary) private var library

    var body: some View {
        List {
            Section {
                Text("Nana helps young adults stay prepared and learn the essentials of sexual health, one minute at a time.")
            }

            Section {
                LabeledContent("Lessons", value: library.curriculum.lessons.count, format: .number)
                LabeledContent("Medical review", value: reviewStatus)
            } header: {
                Text("How lessons are made")
            } footer: {
                Text("Every lesson is based on public guidance from organisations like WHO, UNESCO, UNAIDS and the CDC. Lessons are information, not medical advice. For personal advice, talk to a doctor or nurse.")
            }

            Section("Sources") {
                ForEach(library.sources.values.sorted { $0.publisher < $1.publisher }) { source in
                    Link(destination: source.url) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(source.title)
                                .foregroundStyle(Color.textPrimary)
                            Text("\(source.publisher)\(source.year.map { ", \($0)" } ?? "")")
                                .font(.footnote)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .nanaCanvas()
        .navigationTitle("Help and project information")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var reviewStatus: String {
        let reviewed = library.curriculum.lessons.filter { $0.review.reviewer != nil }.count
        return reviewed == library.curriculum.lessons.count
            ? String(localized: "Complete")
            : String(localized: "Pending")
    }
}

import SwiftUI

/// "Get help" action shown after lessons that point to care.
///
/// Local service details (cost, hours, who is eligible) are not verified yet
/// (Docs/CONTENT.md §9), so this only states WHO-backed timing and hands off to
/// Apple Maps. Maps uses its own location, so Nana never asks for location access.
struct GetHelpCard: View {
    var kind: Curriculum.Lesson.GetHelp

    @Environment(\.openURL) private var openURL

    var body: some View {
        NanaCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: symbol)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(buttonTitle, systemImage: "map") {
                    if let url = mapsURL { openURL(url) }
                }
                .nanaSecondaryButton()
                .controlSize(.regular)
            }
        }
    }

    private var title: LocalizedStringKey {
        kind == .pep ? "Need help in the next 72 hours?" : "Find testing near you"
    }

    private var message: LocalizedStringKey {
        kind == .pep
            ? "PEP works best when started as soon as possible, ideally within 24 hours and no later than 72 hours. Go to a hospital emergency department or clinic and say you may have been exposed."
            : "Many Puskesmas and clinics offer STI and HIV testing. Ask what's available when you visit."
    }

    private var symbol: String { kind == .pep ? "cross.case" : "testtube.2" }

    private var buttonTitle: LocalizedStringKey { kind == .pep ? "Find a hospital" : "Find a Puskesmas" }

    private var mapsURL: URL? {
        let query = kind == .pep ? "Rumah Sakit" : "Puskesmas"
        var components = URLComponents(string: "maps://")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        return components?.url
    }
}

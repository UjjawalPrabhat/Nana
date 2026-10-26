import SwiftUI

/// Lets you swap to a plainer icon if others see your Home Screen.
struct AppIconPicker: View {
    enum Icon: String, CaseIterable, Identifiable {
        case charm, planner, plain

        var id: String { rawValue }

        /// `nil` is the primary icon.
        var alternateName: String? {
            switch self {
            case .charm: nil
            case .planner: "AppIconPlanner"
            case .plain: "AppIconPlain"
            }
        }

        var title: LocalizedStringKey {
            switch self {
            case .charm: "Charm"
            case .planner: "Planner"
            case .plain: "Plain"
            }
        }
    }

    @State private var selection = Icon.allCases.first { $0.alternateName == UIApplication.shared.alternateIconName } ?? .charm

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App icon").font(.nanaLabel)
            HStack(spacing: 10) {
                ForEach(Icon.allCases) { icon in
                    let isSelected = icon == selection
                    Button {
                        select(icon)
                    } label: {
                        VStack(spacing: 6) {
                            IconPreview(icon: icon)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(.nightInk, lineWidth: isSelected ? 4 : 2)
                                }
                            Text(icon.title).font(.nanaCaption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("App icon")
            Text("Pick a plainer icon if you share your phone or your home screen.")
                .font(.nanaCaption)
                .foregroundStyle(.inkSoft)
        }
        .nanaCard()
    }

    private func select(_ icon: Icon) {
        guard icon != selection else { return }
        let previous = selection
        selection = icon
        Task {
            do {
                try await UIApplication.shared.setAlternateIconName(icon.alternateName)
            } catch {
                selection = previous
            }
        }
    }
}

/// The three icons, drawn the way `Tools/AppIcon/render.swift` renders them.
private struct IconPreview: View {
    var icon: AppIconPicker.Icon

    var body: some View {
        ZStack {
            switch icon {
            case .charm:
                Color.cobalt
                Text(verbatim: "n")
                    .font(.custom("BricolageGrotesqueCondensed-ExtraBold", size: 44, relativeTo: .title))
                    .foregroundStyle(.butter)
                    .dynamicTypeSize(.large)
            case .planner:
                Color.banana
                Image(systemName: "checkmark")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(.nightInk)
            case .plain:
                Color.white
                Circle().fill(.lilac).frame(width: 25, height: 25)
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityHidden(true)
    }
}

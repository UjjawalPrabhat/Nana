import SwiftUI

struct RootView: View {
    @AppStorage(AppSettings.hasOnboarded) private var hasOnboarded = false

    var body: some View {
        PrivacyGate {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingFlow {
                    withAnimation { hasOnboarded = true }
                }
            }
        }
    }
}

struct MainTabView: View {
    enum Section: String {
        case home, learn, settings
    }

    @State private var selection = Self.initialSection
    @State private var debugLesson = Self.initialLesson

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView()
            }
            Tab("Learn", systemImage: "leaf", value: .learn) {
                LearnView()
            }
            Tab("Settings", systemImage: "gearshape", value: Section.settings) {
                SettingsView()
            }
        }
        .fullScreenCover(item: $debugLesson) { lesson in
            LessonPlayerView(lesson: lesson)
        }
    }

    // Debug builds accept `-NanaStartTab learn` and `-NanaOpenLesson <id>` for screenshots and UI tests.
    private static var initialSection: Section {
        #if DEBUG
        UserDefaults.standard.string(forKey: "NanaStartTab").flatMap(Section.init) ?? .home
        #else
        .home
        #endif
    }

    private static var initialLesson: Curriculum.Lesson? {
        #if DEBUG
        let id = UserDefaults.standard.string(forKey: "NanaOpenLesson")
        return ContentLibrary.bundled.curriculum.lessons.first { $0.id == id }
        #else
        nil
        #endif
    }
}

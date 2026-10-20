import Foundation
import SwiftData

/// A finished lesson. Quiz answers are deliberately not stored: no scores are kept.
@Model
final class LessonCompletion {
    @Attribute(.unique) var lessonID: String
    var completedAt: Date

    init(lessonID: String, completedAt: Date = .now) {
        self.lessonID = lessonID
        self.completedAt = completedAt
    }
}

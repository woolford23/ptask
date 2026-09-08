import Foundation
import SwiftData

@Model
final class CalendarEvent {
    var title: String
    var notes: String
    var date: Date
    var color: String

    init(title: String, notes: String = "", date: Date, color: String = "blue") {
        self.title = title
        self.notes = notes
        self.date = date
        self.color = color
    }
}


import SwiftData
import SwiftUI

struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let event: CalendarEvent?
    let selectedDate: Date
    @State private var title: String
    @State private var notes: String
    @State private var date: Date

    init(event: CalendarEvent?, selectedDate: Date) {
        self.event = event
        self.selectedDate = selectedDate
        _title = State(initialValue: event?.title ?? "")
        _notes = State(initialValue: event?.notes ?? "")
        _date = State(initialValue: event?.date ?? selectedDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                DatePicker("Date and time", selection: $date)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)

                if event != nil {
                    Button("Delete Event", role: .destructive) {
                        if let event {
                            modelContext.delete(event)
                        }
                        dismiss()
                    }
                }
            }
            .navigationTitle(event == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if let event {
            event.title = trimmedTitle
            event.notes = notes
            event.date = date
        } else {
            modelContext.insert(CalendarEvent(title: trimmedTitle, notes: notes, date: date))
        }
        dismiss()
    }
}


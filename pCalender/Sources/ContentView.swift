import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CalendarEvent.date) private var events: [CalendarEvent]
    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()
    @State private var showingEditor = false
    @State private var eventToEdit: CalendarEvent?

    private var selectedEvents: [CalendarEvent] {
        events.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthHeader
                calendarGrid
                Divider()
                eventList
            }
            .navigationTitle("pCalender")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        eventToEdit = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add event")
                }
            }
            .sheet(isPresented: $showingEditor) {
                EventEditorView(event: eventToEdit, selectedDate: selectedDate)
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.headline)

            Spacer()

            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
    }

    private var calendarGrid: some View {
        let days = displayedMonth.calendarDays

        return VStack(spacing: 8) {
            HStack {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday.prefix(2))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(days, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        hasEvents: events.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
                    ) {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    private var eventList: some View {
        List {
            Section {
                if selectedEvents.isEmpty {
                    ContentUnavailableView("No Events", systemImage: "calendar", description: Text("Tap + to add an event."))
                } else {
                    ForEach(selectedEvents) { event in
                        Button {
                            eventToEdit = event
                            showingEditor = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                if !event.notes.isEmpty {
                                    Text(event.notes)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteEvents)
                }
            } header: {
                Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day())
            }
        }
        .listStyle(.insetGrouped)
    }

    private func deleteEvents(at offsets: IndexSet) {
        offsets.map { selectedEvents[$0] }.forEach(modelContext.delete)
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasEvents: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(date, format: .dateTime.day())
                    .font(.body.weight(isSelected ? .bold : .regular))
                    .frame(width: 34, height: 34)
                    .background(isSelected ? Color.accentColor : .clear)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .clipShape(Circle())

                Circle()
                    .fill(hasEvents ? Color.accentColor : .clear)
                    .frame(width: 5, height: 5)
            }
        }
        .buttonStyle(.plain)
    }
}

private extension Date {
    var calendarDays: [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: self),
              let gridInterval = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        let start = calendar.date(byAdding: .day, value: -calendar.component(.weekday, from: monthInterval.start) + 1, to: monthInterval.start) ?? gridInterval.start
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}


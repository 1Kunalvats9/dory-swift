//
//  EventKitService.swift
//  dory
//
//  Created by Kunal Vats on 08/01/26.
//

import Foundation
import EventKit

@MainActor
final class EventKitService {
    static let shared = EventKitService()
    private let store = EKEventStore()

    private init() {}
    
    func requestReminderAccess() async throws {
            let status = EKEventStore.authorizationStatus(for: .reminder)

            switch status {
            case .authorized:
                return

            case .notDetermined:
                let granted = try await store.requestAccess(to: .reminder)
                if !granted {
                    throw EventKitError.permissionDenied
                }

            default:
                throw EventKitError.permissionDenied
            }
    }
    
    func createReminders(from events: [DetectedEvent]) async throws {
            try await requestReminderAccess()

            let calendar = store.defaultCalendarForNewReminders()

            for event in events {
                let reminder = EKReminder(eventStore: store)
                reminder.calendar = calendar
                reminder.title = event.title

                if let start = event.startTime {
                    let due = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute],
                        from: start
                    )
                    reminder.dueDateComponents = due

                    // Optional: alert 10 minutes before
                    let alarm = EKAlarm(
                        relativeOffset: -10 * 60
                    )
                    reminder.addAlarm(alarm)
                }

                try store.save(reminder, commit: false)
            }

            try store.commit()
        }
}


enum EventKitError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Reminder access was denied. Please enable it in Settings."
        }
    }
}

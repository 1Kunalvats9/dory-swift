//
//  DetectedEventsViewModel.swift
//  dory
//
//  Created by Kunal Vats on 08/01/26.
//

import Foundation
import Combine

@MainActor
final class DetectedEventsViewModel: ObservableObject {
    @Published var events: [DetectedEvent] = []
    @Published var selectedEventIds: Set<String> = []
    @Published var isLoading = false
    @Published var error: String?
    
    func load(documentId: String) async {
        isLoading = true
        error = nil
        
        do{
            print("Fetching detected events for documentId: \(documentId)")
            let response = try await APIService.shared.fetchDetectedEvents(documentId: documentId)
            print("Received detected events response: \(response.events.count) events")
            print("Events data: \(response.events)")
            self.events = response.events
            self.selectedEventIds = Set(response.events.map { $0.id })
            print("Selected event IDs: \(self.selectedEventIds)")
        }catch {
            print("Error fetching events: \(error)")
            if let apiError = error as? APIError {
                self.error = apiError.localizedDescription
            } else {
                self.error = "Failed to load events: \(error.localizedDescription)"
            }
        }

        isLoading = false
    }
    
    func toggle(_ event: DetectedEvent) {
            if selectedEventIds.contains(event.id) {
                selectedEventIds.remove(event.id)
            } else {
                selectedEventIds.insert(event.id)
            }
    }

    var selectedEvents: [DetectedEvent] {
        events.filter { selectedEventIds.contains($0.id) }
    }

}

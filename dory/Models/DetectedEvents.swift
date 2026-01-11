//
//  DetectedEvents.swift
//  dory
//
//  Created by Kunal Vats on 08/01/26.
//

import Foundation

struct DetectedEvent: Identifiable, Decodable {
    let id: String
    let title: String
    let startTime: Date?
    let endTime: Date?
    let recurrence: String?
    let confidence: Double
    let sourceText: String?
}

struct DetectedEventsResponse: Decodable {
    let success: Bool
    let data: DetectedEventsData
}

struct DetectedEventsData: Decodable {
    let events: [DetectedEvent]
    let count: Int
}

extension APIService {
    func fetchDetectedEvents(documentId: String) async throws -> DetectedEventsData {
        print("Fetching detected events from: /api/documents/\(documentId)/events")
        let response: DetectedEventsResponse = try await request(
            endpoint: "/api/documents/\(documentId)/events",
            requiresAuth: true
        )
        print("DetectedEventsResponse received, count: \(response.data.count), events: \(response.data.events.map { $0.title })")
        return response.data
    }
}

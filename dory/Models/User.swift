//
//  User.swift
//  dory
//
//  Created by Kunal Vats on 25/12/25.
//

import Foundation
struct User: Codable, Identifiable {
    let userID: String
    let email: String
    let name: String?
    let profilePhoto: String?
    let createdAt: String?
    let updatedAt: String?
    let googleID: String?
    
    var id: String { userID }
    
    var createdAtDate: Date? {
        guard let createdAt = createdAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: createdAt) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: createdAt)
    }
    
    var displayName: String {
        name ?? email.components(separatedBy: "@").first ?? "User"
    }
    
    enum CodingKeys: String, CodingKey {
        case userID = "ID"
        case email = "Email"
        case name = "Name"
        case profilePhoto = "ProfilePhoto"
        case createdAt = "CreatedAt"
        case updatedAt = "UpdatedAt"
        case googleID = "GoogleID"
    }
}

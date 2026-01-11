//
//  AuthResponse.swift
//  dory
//
//  Created by Kunal Vats on 25/12/25.
//

import Foundation

// Backend returns: {"token": "...", "user": {...}}
struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct UserResponse: Codable {
    let success: Bool
    let data: User
}

struct MessageResponse: Codable {
    let success: Bool
    let data: MessageData
}

struct MessageData: Codable {
    let message: String
}

struct ErrorResponse: Codable {
    let success: Bool
    let error: String
}

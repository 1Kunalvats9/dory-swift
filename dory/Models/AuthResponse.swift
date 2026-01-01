//
//  AuthResponse.swift
//  dory
//
//  Created by Kunal Vats on 25/12/25.
//

import Foundation

struct AuthResponse: Codable {
    let success: Bool
    let data: AuthData
}

struct AuthData: Codable {
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

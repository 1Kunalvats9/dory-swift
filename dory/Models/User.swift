//
//  User.swift
//  dory
//
//  Created by Kunal Vats on 25/12/25.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String?
    let profilePhoto: String?
    let createdAt: Date
    var displayName: String{
        name ?? email.components(separatedBy: "@").first ?? "User"
    }
    
}

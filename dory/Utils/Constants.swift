//
//  Constants.swift
//  dory
//
//  Created by Kunal Vats on 25/12/25.
//

import Foundation

struct Constants{
    static let baseURL = "https://dorry-backend.onrender.com"
    static let googleClientID = "291795876648-jul571i80msdh2bgnlnrn0brohbnvlad.apps.googleusercontent.com"
    
    struct Endpoints {
            static let googleLogin = "/api/auth/google/login"
            static let me = "/api/auth/me"
            static let deleteAccount = "/api/auth/me"
    }
    struct KeychainKeys {
            static let jwtToken = "jwt_token"
            static let userId = "user_id"
    }
}

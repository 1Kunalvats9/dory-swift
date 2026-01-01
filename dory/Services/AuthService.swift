//
//  AuthService.swift
//  dory
//
//  Created by Kunal Vats on 25/12/25.
//

import Foundation
import GoogleSignIn

class AuthService {
    
    static let shared = AuthService()
    private init() {}

    func signInWithGoogle() async throws -> AuthResponse {
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Unable to find root view controller"
            ])
        }
        
        let config = GIDConfiguration(clientID: Constants.googleClientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController
        )
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "AuthService", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Failed to get ID token from Google"
            ])
        }
        
        let authResponse = try await APIService.shared.loginWithGoogle(idToken: idToken)
        
        let saved = KeychainService.save(token: authResponse.data.token)
        if saved {
            print("JWT token saved to Keychain")
        } else {
            print("Failed to save JWT token")
        }
        
        return authResponse
    }
    
    
    func checkAuthStatus() async -> User? {
        guard KeychainService.load() != nil else {
            return nil
        }
        
        do {
            let response = try await APIService.shared.getCurrentUser()
            return response.data
        } catch {
            print("Token validation failed: \(error.localizedDescription)")
            KeychainService.clearAll()
            return nil
        }
    }
    
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        
        KeychainService.clearAll()
        
        print("Signed out successfully")
    }
}

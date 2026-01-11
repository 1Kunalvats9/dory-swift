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
        
        // Save JWT token to keychain
        let saved = KeychainService.save(token: authResponse.token)
        if saved {
            print("JWT token saved to Keychain")
        } else {
            print("Failed to save JWT token")
        }
        
        // Save user data to UserDefaults for persistence
        saveUser(authResponse.user)
        
        return authResponse
    }
    
    
    func checkAuthStatus() async -> User? {
        // Check if token exists in keychain
        guard KeychainService.load() != nil else {
            // No token means not logged in
            clearUser()
            return nil
        }
        
        // Token exists, try to load user from UserDefaults
        if let user = loadUser() {
            print("✅ User restored from UserDefaults: \(user.email)")
            return user
        }
        
        // Token exists but no user data - shouldn't happen, but clear to be safe
        print("⚠️ Token exists but no user data found")
        return nil
    }
    
    // MARK: - User Persistence
    
    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: Constants.UserDefaultsKeys.currentUser)
            print("✅ User saved to UserDefaults: \(user.email)")
        } else {
            print("❌ Failed to encode user data")
        }
    }
    
    private func loadUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.currentUser),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user
    }
    
    private func clearUser() {
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.currentUser)
    }
    
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        
        // Clear token from keychain
        KeychainService.clearAll()
        
        // Clear user data from UserDefaults
        clearUser()
        
        print("Signed out successfully")
    }
}

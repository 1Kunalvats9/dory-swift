//
//  AuthViewModel.swift
//  dory
//
//  Created by Kunal Vats on 25/12/25.
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    
    init() {
        Task {
            await checkAuthStatus()
        }
    }
    
    func checkAuthStatus() async {
        isLoading = true
        
        let user = await AuthService.shared.checkAuthStatus()
        
        if let user = user {
            self.user = user
            self.isAuthenticated = true
            print("User is authenticated: \(user.email)")
        } else {
            self.user = nil
            self.isAuthenticated = false
            print("User is not authenticated")
        }
        
        isLoading = false
    }
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await AuthService.shared.signInWithGoogle()
            
            self.user = response.data.user
            self.isAuthenticated = true
            
            print("Login successful: \(response.data.user.email)")
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("Login failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        AuthService.shared.signOut()
        
        self.user = nil
        self.isAuthenticated = false
        
        print("Signed out")
    }
}

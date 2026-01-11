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
        } else {
            self.user = nil
            self.isAuthenticated = false
        }
        
        isLoading = false
    }
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await AuthService.shared.signInWithGoogle()
            
            self.user = response.user
            self.isAuthenticated = true
        
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("Login failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    
    func signOut() {
        AuthService.shared.signOut()
        
        self.user = nil
        self.isAuthenticated = false
        
    }
}

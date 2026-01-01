//
//  doryApp.swift
//  dory
//
//  Created by Kunal Vats on 25/12/25.
//

import SwiftUI
import GoogleSignIn

@main
struct doryApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)  // Share across all views
                .onOpenURL { url in
                    // Handle Google Sign-In callback
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

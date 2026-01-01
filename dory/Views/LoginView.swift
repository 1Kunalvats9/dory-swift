//
//  LoginView.swift
//  dory
//
//  Created by Kunal Vats on 25/12/25.
//
import SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            // Your existing blurred background
            BlurredBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                Spacer()
                
                VStack(spacing: 16) {
                    
                    VStack(spacing: 8) {
                        Text("Welcome to Dory")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Your companion to learn everything for you")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
                .padding(.top, 60)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                
                Spacer()
                
                VStack(spacing: 24) {

                    Button(action: {
                        Task{
                            await authViewModel.signInWithGoogle()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image("google_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                            
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: 300)
                        .frame(height: 54)
                        .glassEffect(.clear.interactive(),in:.rect(cornerRadius: 16))
                    }
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 40)
                
                
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0)) {
                animateIn = true
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}

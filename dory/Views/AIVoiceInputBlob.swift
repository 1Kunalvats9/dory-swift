//
//  AIVoiceInputBlob.swift
//  dory
//
//  Created by Kunal Vats on 01/01/26.
//

import SwiftUI
import AVKit

struct AIVoiceInputBlob: View {
    @ObservedObject var viewModel: SpeechInputViewModel
    let onClose: () -> Void
    
    @State private var showPermissionAlert = false
    @State private var permissionMessage = ""

    private let videoURL = URL(
        string: "https://cdn.dribbble.com/userupload/3216507/file/original-2a7a6e02d99d870b3ea0982657ba3cce.mp4"
    )!

    var body: some View {
        ZStack {
            // Video background - always visible and playing
            LoopingVideoBackgroundView(videoURL: videoURL, shouldPlay: true)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            VStack(spacing: 30) {
                Spacer()
                
                // Transcript display
                if !viewModel.transcript.isEmpty {
                    VStack(spacing: 12) {
                        Text("Transcript")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        ScrollView {
                            Text(viewModel.transcript)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: 300)
                                .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(.horizontal)
                }
                
                // Recording indicator
                if viewModel.isRecording {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .opacity(viewModel.isRecording ? 1 : 0.5)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.isRecording)
                        
                        Text("Recording...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 20))
                }
                
                // Control buttons
                HStack(spacing: 20) {
                    // Stop/End button
                    Button(action: {
                        handleStop()
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .glassEffect(.clear.interactive(), in: .circle)
                    }
                    .disabled(viewModel.isLoading)
                    
                    // Close button (only show when not recording)
                    if !viewModel.isRecording && !viewModel.isLoading {
                        Button(action: {
                            onClose()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.7))
                                .glassEffect(.clear.interactive(), in: .circle)
                        }
                    }
                }
                .padding(.bottom, 50)
                
                // Loading indicator
                if viewModel.isLoading {
                    ProgressView("Sending transcript...")
                        .padding()
                        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
                }
                
                // Success message
                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                        .foregroundColor(.white)
                        .padding()
                        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
                        .onAppear {
                            // Auto close after showing success
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                onClose()
                            }
                        }
                }
            }
        }
        .onAppear {
            startRecording()
        }
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("OK", role: .cancel) {
                onClose()
            }
        } message: {
            Text(permissionMessage)
        }
    }
    
    private func startRecording() {
        Task {
            let hasPermission = await viewModel.requestPermission()
            
            if hasPermission {
                do {
                    try viewModel.startRecording()
                } catch {
                    permissionMessage = "Failed to start recording: \(error.localizedDescription)"
                    showPermissionAlert = true
                }
            } else {
                permissionMessage = "Please enable microphone and speech recognition permissions in Settings."
                showPermissionAlert = true
            }
        }
    }
    
    private func handleStop() {
        viewModel.stopRecording()
        
        if !viewModel.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task {
                await viewModel.ingest()
            }
        } else {
            onClose()
        }
    }
}


#Preview {
    AIVoiceInputBlob(
        viewModel: SpeechInputViewModel(),
        onClose: {}
    )
}

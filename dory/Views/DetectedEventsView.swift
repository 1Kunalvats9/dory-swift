//
//  DetectedEventsView.swift
//  dory
//
//  Created by Kunal Vats on 08/01/26.
//

import SwiftUI

struct DetectedEventsView: View {

    let documentId: String
    let onConfirm: ([DetectedEvent]) -> Void
    let onDismiss: () -> Void

    @StateObject private var viewModel = DetectedEventsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                BlurredBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Analyzing document")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.error {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.red)
                            
                            VStack(spacing: 8) {
                                Text("Something went wrong")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(error)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                            }
                            
                            Button(action: {
                                Task {
                                    await viewModel.load(documentId: documentId)
                                }
                            }) {
                                Text("Try Again")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 12))
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.events.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 52))
                                .foregroundColor(.white.opacity(0.6))
                            
                            VStack(spacing: 6) {
                                Text("No events detected")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("This document doesn't contain any calendar events or meetings")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 0) {
                            Text("Found \(viewModel.events.count) Event\(viewModel.events.count == 1 ? "" : "s")")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.events) { event in
                                        DetectedEventRowGlass(
                                            event: event,
                                            isSelected: viewModel.selectedEventIds.contains(event.id)
                                        ) {
                                            viewModel.toggle(event)
                                        }
                                    }
                                }
                                .padding(12)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
                
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: onDismiss) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 12))
                        }
                        
                        Button(action: {
                            onConfirm(viewModel.selectedEvents)
                        }) {
                            Text("Create Reminders (\(viewModel.selectedEvents.count))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    viewModel.selectedEvents.isEmpty
                                        ? Color.white.opacity(0.2)
                                        : Color.blue.opacity(0.6)
                                )
                                .cornerRadius(12)
                        }
                        .disabled(viewModel.selectedEvents.isEmpty)
                    }
                    .padding(12)
                }
            }
            .navigationTitle("Calendar Events")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            print("Detected events view appeared for document:", documentId)
            Task {
                await viewModel.load(documentId: documentId)
            }
        }
    }
}

struct DetectedEventRowGlass: View {
    let event: DetectedEvent
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.7) : Color.white.opacity(0.2))
                    
                    Image(systemName: isSelected ? "checkmark" : "")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    VStack(alignment: .leading, spacing: 3) {
                        if let start = event.startTime {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text(start.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 13, weight: .regular))
                            }
                            .foregroundColor(.white.opacity(0.7))
                        }

                        if let recurrence = event.recurrence {
                            HStack(spacing: 4) {
                                Image(systemName: "repeat")
                                    .font(.system(size: 12))
                                Text(recurrence)
                                    .font(.system(size: 13, weight: .regular))
                            }
                            .foregroundColor(.white.opacity(0.7))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal")
                                .font(.system(size: 12))
                            Text("\(Int(event.confidence * 100))% confidence")
                                .font(.system(size: 13, weight: .regular))
                        }
                        .foregroundColor(.green.opacity(0.7))
                    }
                }

                Spacer()
            }
            .padding(12)
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DetectedEventsView(
        documentId: "test-id",
        onConfirm: { _ in },
        onDismiss: { }
    )
}
//
//#Preview {
//    DetectedEventsView()
//}

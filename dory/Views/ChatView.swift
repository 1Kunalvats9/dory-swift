//
//  ChatView.swift
//  dory
//
//  Created by Kunal Vats on 28/12/25.
//

import SwiftUI
import Combine

struct ChatView: View {

    @StateObject private var vm = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            // MARK: - Background
            BlurredBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Messages ScrollView
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(vm.messages) { message in
                                HStack(alignment: .top, spacing: 8) {
                                    if message.isUser {
                                        Spacer(minLength: 50)
                                        messageBubble(
                                            text: message.text,
                                            isUser: true
                                        )
                                    } else {
                                        messageBubble(
                                            text: message.text,
                                            isUser: false
                                        )
                                        Spacer(minLength: 50)
                                    }
                                }
                                .id(message.id)
                            }

                            if vm.isLoading {
                                HStack {
                                    ProgressView()
                                        .padding(12)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                    Spacer()
                                }
                                .id("loading")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .frame(width: 410)
                    .onChange(of: vm.messages.count) { _, _ in
                        scrollToBottom(proxy)
                    }
                    .onChange(of: vm.isLoading) { _, _ in
                        scrollToBottom(proxy)
                    }
                }

                // MARK: - Error Message
                if let errorMessage = vm.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .frame(width: 410)
                }

                // MARK: - Input Bar
                inputBar
            }
            .frame(width: 410)
        }
    }

    // MARK: - Message Bubble
    @ViewBuilder
    private func messageBubble(text: String, isUser: Bool) -> some View {
        Text(text)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 20))
            .frame(maxWidth: 260, alignment: isUser ? .trailing : .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Ask something…", text: $vm.inputText, axis: .vertical)
                .focused($isInputFocused)
                .lineLimit(1...5)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .onSubmit {
                    sendMessage()
                }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }
            .disabled(
                vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || vm.isLoading
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 410)
    }

    // MARK: - Helpers
    private func sendMessage() {
        guard !vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isInputFocused = false
        Task {
            await vm.sendMessage(useRAG: true)
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.25)) {
                if vm.isLoading {
                    proxy.scrollTo("loading", anchor: .bottom)
                } else if let lastId = vm.messages.last?.id {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
    }
}


#Preview{
    ChatView()
}

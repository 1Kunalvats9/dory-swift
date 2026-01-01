//
//  ChatViewModel.swift
//  dory
//
//  Created by Kunal Vats on 28/12/25.
//

import Foundation
import Combine

struct ChatResponse: Decodable {
    let success: Bool
    let data: ChatData
}

struct ChatData: Decodable {
    let chatId: String
    let response: String
    let retrievedChunks: [RetrievedChunk]
}

struct RetrievedChunk: Decodable, Identifiable {
    let chunk_id: String
    let document_id: String
    let score: Double

    var id: String { chunk_id }
}

struct ChatRequest: Encodable {
    let message: String
    let chatId: String?
    let useRAG: Bool
}


struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}


@MainActor
final class ChatViewModel: ObservableObject {

    // MARK: - UI State

    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Chat Context

    private(set) var chatId: String?

    // MARK: - Actions

    func sendMessage(useRAG: Bool = true) async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Add user message immediately
        messages.append(ChatMessage(text: trimmed, isUser: true))
        let messageToSend = trimmed
        inputText = ""
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.sendMessage(
                message: messageToSend,
                chatId: chatId,
                useRAG: useRAG
            )

            // Persist chatId for future messages
            chatId = response.data.chatId

            // Add AI response
            messages.append(
                ChatMessage(
                    text: response.data.response,
                    isUser: false
                )
            )

        } catch let error as APIError {
            errorMessage = error.localizedDescription
            print("❌ API Error: \(error.localizedDescription)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Reset (Optional)

    func startNewChat() {
        chatId = nil
        messages.removeAll()
    }
}

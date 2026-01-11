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
    let message: String?
    let data: ChatData
}

struct ChatData: Decodable {
    let response: String
    let sources: [String]
}

struct ChatRequest: Encodable {
    let message: String
}


struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}


@MainActor
final class ChatViewModel: ObservableObject {


    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private(set) var chatId: String?


    func sendMessage(useRAG: Bool = true) async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

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

            messages.append(
                ChatMessage(
                    text: response.data.response,
                    isUser: false
                )
            )

        } catch let error as APIError {
            errorMessage = error.localizedDescription
            print("API Error: \(error.localizedDescription)")
        } catch {
            errorMessage = error.localizedDescription
            print("Error: \(error.localizedDescription)")
        }

        isLoading = false
    }
    func startNewChat() {
        chatId = nil
        messages.removeAll()
    }
}

//
//  APIService.swift
//  dory
//
//  Created by Kunal Vats on 25/12/25.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case decodingError
    case networkError(Error)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            return "Error \(statusCode): \(message)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized - please login again"
        }
    }
}

class APIService {
    
    static let shared = APIService()
    private init() {}
    
    private static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = fallbackFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateString)"
            )
        }
        return decoder
    }()
    
    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        
        guard let url = URL(string: Constants.baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth {
            guard let token = KeychainService.load() else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("HTTP \(httpResponse.statusCode) for \(method) \(endpoint)")
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Response data: \(jsonString.prefix(500))")
                    }
                    return try APIService.jsonDecoder.decode(T.self, from: data)
                } catch {
                    print("Decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Response data: \(jsonString)")
                    }
                    throw APIError.decodingError
                }
                
            case 401:
                throw APIError.unauthorized
                
            default:
                if let errorResponse = try? APIService.jsonDecoder.decode(ErrorResponse.self, from: data) {
                    throw APIError.httpError(
                        statusCode: httpResponse.statusCode,
                        message: errorResponse.error
                    )
                }
                throw APIError.httpError(
                    statusCode: httpResponse.statusCode,
                    message: "Unknown error"
                )
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func loginWithGoogle(idToken: String) async throws -> AuthResponse {
        struct LoginBody: Encodable {
            let idToken: String
        }
        
        return try await request(
            endpoint: Constants.Endpoints.googleLogin,
            method: "POST",
            body: LoginBody(idToken: idToken)
        )
    }
    
    func getCurrentUser() async throws -> UserResponse {
        return try await request(
            endpoint: Constants.Endpoints.me,
            requiresAuth: true
        )
    }
    
    func deleteAccount() async throws -> MessageResponse {
        return try await request(
            endpoint: Constants.Endpoints.deleteAccount,
            method: "DELETE",
            requiresAuth: true
        )
    }
}

extension APIService {

    func sendMessage(
        message: String,
        chatId: String?,
        useRAG: Bool = true
    ) async throws -> ChatResponse {

        let body = ChatRequest(
            message: message,
            chatId: chatId,
            useRAG: useRAG
        )

        let response: ChatResponse = try await request(
            endpoint: "/api/chat",
            method: "POST",
            body: body,
            requiresAuth: true
        )
        return response
    }

}

extension APIService {

    func getDocument(documentId: String) async throws -> DocumentResponse {
        return try await request(
            endpoint: "/api/documents/\(documentId)",
            requiresAuth: true
        )
    }
}

struct DocumentResponse: Decodable {
    let success: Bool
    let data: DocumentData
}

struct DocumentData: Decodable {
    let id: String
    let status: String
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}


extension APIService {

    func ingestPDF(fileURL: URL) async throws -> PDFIngestResponse {

        guard let url = URL(string: Constants.baseURL + "/api/ingest/pdf") else {
            throw APIError.invalidURL
        }

        guard let token = KeychainService.load() else {
            throw APIError.unauthorized
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        var body = Data()

        let filename = fileURL.lastPathComponent
        let fileData = try Data(contentsOf: fileURL)

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: application/pdf\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try APIService.jsonDecoder.decode(PDFIngestResponse.self, from: data)
        case 401:
            throw APIError.unauthorized
        default:
            if let errorResponse = try? APIService.jsonDecoder.decode(ErrorResponse.self, from: data) {
                throw APIError.httpError(
                    statusCode: httpResponse.statusCode,
                    message: errorResponse.error
                )
            }
            throw APIError.httpError(
                statusCode: httpResponse.statusCode,
                message: "Unknown error"
            )
        }
    }
}



extension APIService {
    
    func ingestText(
        text: String,
        filename: String? = nil
    ) async throws -> IngestResponse {
        
        let body = IngestRequest(
            text: text,
            filename: filename
        )
        
        return try await request(
            endpoint: "/api/ingest",
            method: "POST",
            body: body,
            requiresAuth: true
        )
    }
}


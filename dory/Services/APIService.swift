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
    
    func request<T: Decodable>(
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
                // Backend error format: {"success": false, "error": "...", "message": "..."}
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
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
        
        guard let url = URL(string: Constants.baseURL + Constants.Endpoints.googleLogin) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(LoginBody(idToken: idToken))
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // Debug: Print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("✅ Auth Response JSON: \(jsonString)")
            }
            
            // Try to decode with plain decoder
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(AuthResponse.self, from: data)
            } catch let decodingError as DecodingError {
                // Print detailed decoding error
                print("❌ Decoding Error: \(decodingError)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("❌ Response JSON was: \(jsonString)")
                }
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Missing key: \(key.stringValue) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch for type: \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found for type: \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")), error: \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
                throw APIError.decodingError
            } catch {
                print("❌ Error decoding auth response: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("❌ Response JSON was: \(jsonString)")
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
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ Auth Error Response: \(jsonString)")
            }
            throw APIError.httpError(
                statusCode: httpResponse.statusCode,
                message: "Unknown error"
            )
        }
    }
    
    // Note: /api/auth/me endpoint doesn't exist in backend
    // Removed getCurrentUser() and deleteAccount() methods
}

extension APIService {

    func sendMessage(
        message: String,
        chatId: String? = nil,
        useRAG: Bool = true
    ) async throws -> ChatResponse {

        // Backend only expects message, not chatId or useRAG
        let body = ChatRequest(message: message)

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

// Backend returns: {"success": true, "message": "...", "data": Document}
// Backend Document model has no JSON tags, so fields are capitalized: ID, UserID, Filename, etc.
struct DocumentResponse: Decodable {
    let success: Bool
    let message: String?
    let data: DocumentData
}

struct DocumentData: Decodable {
    let ID: String  // Backend sends "ID" (UUID as string)
    let UserID: String?  // Backend sends "UserID" (UUID as string)
    let Filename: String?
    let FileURL: String?
    let PublicID: String?
    let FileType: String?
    let Content: String?
    let Status: String
    let UploadedAt: String?  // Backend sends time.Time which serializes to string
    
    // CodingKeys to map backend's capitalized field names
    enum CodingKeys: String, CodingKey {
        case ID
        case UserID
        case Filename
        case FileURL
        case PublicID
        case FileType
        case Content
        case Status
        case UploadedAt
    }
    
    // Computed properties for easier use (camelCase)
    var id: String { ID }
    var user_id: String? { UserID }
    var filename: String? { Filename }
    var file_url: String? { FileURL }
    var file_type: String? { FileType }
    var content: String? { Content }
    var status: String { Status }
    var uploaded_at: String? { UploadedAt }
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
            content: text,
            filename: filename
        )
        
        return try await request(
            endpoint: "/api/ingest/text",
            method: "POST",
            body: body,
            requiresAuth: true
        )
    }
}




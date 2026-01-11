//
//  TextViewModel.swift
//  dory
//
//  Created by Kunal Vats on 28/12/25.
//

import Foundation
import Combine

struct IngestResponse: Decodable {
    let success: Bool
    let message: String?
    let data: IngestData
}

struct IngestData: Decodable {
    let ID: String
    let UserID: String?
    let Filename: String?
    let FileURL: String?
    let PublicID: String?
    let FileType: String?
    let Content: String?
    let Status: String
    let UploadedAt: String?
    

    var id: String { ID }
    var documentId: String { ID }
    var chunksStored: Int { 0 }
    
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
}

struct IngestRequest: Encodable {
    let content: String
    let filename: String?
}

@MainActor
final class TextViewModel: ObservableObject {
    
    
    @Published var text: String = ""
    @Published var filename: String = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    @Published var documentId: String?
    @Published var chunksStored: Int?
    
    
    func ingest() async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Text cannot be empty"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let response = try await APIService.shared.ingestText(
                text: text,
                filename: filename.isEmpty ? nil : filename
            )
            
            documentId = response.data.documentId
            chunksStored = response.data.chunksStored
            successMessage = "Ingested successfully"
               
            text = ""
            
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

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
    let data: IngestData
}

struct IngestData: Decodable {
    let documentId: String
    let chunksStored: Int
}

struct IngestRequest: Encodable {
    let text: String
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
            successMessage = "Ingested successfully (\(response.data.chunksStored) chunks)"
            
            // Optional: clear input
            text = ""
            
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

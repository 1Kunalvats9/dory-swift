//
//  PdfIngestViewModel.swift
//  dory
//
//  Created by Kunal Vats on 01/01/26.
//

import Foundation
import Combine

enum PDFIngestState {
    case idle
    case uploading
    case processing(documentId: String)
    case completed(documentId: String)
    case failed(message: String)
}

struct PDFIngestResponse: Decodable {
    let success: Bool
    let data: PDFIngestData
}

struct PDFIngestData: Decodable {
    let documentId: String
    let message: String
    let cloudinaryUrl: String?
}


@MainActor
class PDFIngestViewModel: ObservableObject {

    @Published var state: PDFIngestState = .idle

    private var pollingTask: Task<Void, Never>?

    func uploadPDF(fileURL: URL) {
        state = .uploading

        Task {
            do {
                let response = try await APIService.shared.ingestPDF(fileURL: fileURL)

                let documentId = response.data.documentId
                state = .processing(documentId: documentId)

                startPolling(documentId)
            } catch {
                state = .failed(message: error.localizedDescription)
            }
        }
    }

    func startPolling(_ documentId: String) {
        pollingTask?.cancel()

        pollingTask = Task<Void, Never> {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 4_000_000_000)

                do {
                    let document = try await APIService.shared.getDocument(documentId: documentId)

                    if document.data.status == "ready" {
                        state = .completed(documentId: documentId)
                        return
                    }

                    if document.data.status == "failed" {
                        state = .failed(message: "PDF processing failed")
                        return
                    }
                } catch {
                    // silent retry
                }
            }
        }
    }

    func cancelPolling() {
        pollingTask?.cancel()
    }
}

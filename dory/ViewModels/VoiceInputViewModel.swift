//
//  VoiceInputViewModel.swift
//  dory
//
//  Created by Kunal Vats on 01/01/26.
//

import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
class SpeechInputViewModel: ObservableObject {

    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    @Published var documentId: String?
    @Published var chunksStored: Int?

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer()

    func requestPermission() async -> Bool {

        let speechAuthorized: Bool = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        let micAuthorized: Bool = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        return speechAuthorized && micAuthorized
    }


    func startRecording() throws {
        transcript = ""
        isRecording = true

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer?.recognitionTask(with: request!) { [weak self] result, _ in
            if let result {
                self?.transcript = result.bestTranscription.formattedString
            }
        }
    }

    func stopRecording() {
        isRecording = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()

        request = nil
        task = nil
    }
    
    func ingest() async {
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "No transcript to ingest"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let response = try await APIService.shared.ingestText(
                text: transcript,
                filename: "voice_recording_\(Date().timeIntervalSince1970).txt"
            )
            
            documentId = response.data.documentId
            chunksStored = response.data.chunksStored
            successMessage = "Ingested successfully (\(response.data.chunksStored) chunks)"
            
            // Clear transcript after successful ingestion
            transcript = ""
            
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

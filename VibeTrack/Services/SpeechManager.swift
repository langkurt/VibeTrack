import SwiftUI
import Speech
import AVFoundation

class SpeechManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override init() {
        super.init()
        speechRecognizer?.delegate = self
        requestAuthorization()
        LogManager.shared.log("SpeechManager initialized", category: .speech)
    }
    
    func requestAuthorization() {
        LogManager.shared.log("Requesting speech authorization", category: .speech)
        
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    LogManager.shared.log("Speech recognition authorized", category: .speech)
                case .denied:
                    LogManager.shared.log("Speech recognition denied", category: .speech)
                    self.errorMessage = "Speech recognition denied"
                case .restricted:
                    LogManager.shared.log("Speech recognition restricted", category: .speech)
                    self.errorMessage = "Speech recognition restricted"
                case .notDetermined:
                    LogManager.shared.log("Speech recognition not determined", category: .speech)
                    self.errorMessage = "Speech recognition not determined"
                @unknown default:
                    LogManager.shared.log("Unknown authorization status", category: .speech)
                    self.errorMessage = "Unknown authorization status"
                }
            }
        }
    }
    
    func startRecording() {
        LogManager.shared.log("Start recording requested", category: .speech)
        
        if audioEngine.isRunning {
            LogManager.shared.log("Audio engine already running, stopping", category: .speech)
            stopRecording()
            return
        }
        
        do {
            try startRecordingSession()
            LogManager.shared.log("Recording session started successfully", category: .speech)
        } catch {
            LogManager.shared.logError(error, category: .speech)
            errorMessage = "Recording failed: \(error.localizedDescription)"
        }
    }
    
    private func startRecordingSession() throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechManager", code: 1, userInfo: nil)
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                LogManager.shared.log("Transcribed: \(self.transcribedText)", category: .speech)
            }
            
            if let error = error {
                LogManager.shared.logError(error, category: .speech)
            }
            
            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        transcribedText = "Listening..."
    }
    
    func stopRecording() {
        LogManager.shared.log("Stopping recording", category: .speech)
        
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        
        LogManager.shared.log("Recording stopped", category: .speech)
    }
}

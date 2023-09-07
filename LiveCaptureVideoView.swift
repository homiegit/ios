//
//  LiveView.swift
//  homie-ios
//
//  Created by Diego Lares on 8/22/23.
//

import SwiftUI
import AVFoundation
import CoreMedia
import CoreVideo
import AVKit


struct LiveTimerDisplay: View {
    @Binding var timer: String {
        didSet {
            print("timer updated to:", timer)
        }
    }

    var body: some View {
        VStack {
            
            HStack {
                Text(timer)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .top)

            }
            .padding(EdgeInsets(top: 8 - 60, leading: 8, bottom: 8, trailing: 8))

            Spacer()
            
        }
    }
}


struct LiveCaptureVideoView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    private var captureVideoControllerDelegate: LiveCaptureVideoControllerDelegate?
    @State private var showPermissionAlert = false
    @State private var cameraAccess = false
    @State private var microphoneAccess = false
    @State private var timerDisplay = "00:00"
    
    @State private var showGuidlines: Bool = false
    @State private var goLive: Bool = false

    public var body: some View {
       ZStack {
           if cameraAccess {
               GeometryReader { geometry in
                   VStack {
                       LiveCaptureVideoController(
                           timerDisplay: $timerDisplay,
                           onTimerDisplayUpdated: { newTimerDisplay in
                               timerDisplay = newTimerDisplay
                           },
                           goLive: $goLive,
                           showGuidlines: $showGuidlines
                       )
                         .edgesIgnoringSafeArea(.all)
                           .frame(width: geometry.size.width, height: geometry.size.height)
                           .overlay(TimerDisplay(timer: $timerDisplay))
                           .onChange(of: timerDisplay) { newValue in
                               print("TimerDisplay changed to:", newValue)
                           }
                   }
               }
               .onChange(of: goLive) { newValue in
                   print("new goLive value:", newValue)
                   if newValue == false {
                       //cameraAccess = false
                       //microphoneAccess = false
                   }
               }
           } else {
               Button(action: {
                   // Open Settings when the user taps on the button
                   openAppSettings()
               }) {
                   Text("Please grant camera and microphone access in Settings.")
                       .foregroundColor(.red)
               }
           }
           
           if showGuidlines {
               VStack(alignment: .center) {
                   Text("You will go live if you press 'Go Live'")
                       .font(.system(size: 40))
                       .foregroundColor(.white)
                   
                   HStack(alignment: .center) {
                       Button(action: {
                           showGuidlines = false
                       }) {
                           Text("Cancel")
                               .font(.system(size: 20))
                               .padding(10)
                               .foregroundColor(.white)
                               .border(Color.white, width: 1)
                       }
                       Button(action: {
                           goLive = true
                           //captureVideoControllerDelegate
                           
                       }) {
                           Text("Go Live")
                               .font(.system(size: 20))
                               .padding(10)
                               .foregroundColor(.white)
                               .border(Color.white, width: 1)
                       }
                   }
               }
               .frame(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.height / 2)
               .background(Color.black)
           }
        
       }
       .onAppear {
           checkCameraAccess()
           checkMicrophoneAccess()
       }
   }

    private func checkCameraAccess() {
         switch AVCaptureDevice.authorizationStatus(for: .video) {
         case .notDetermined:
             AVCaptureDevice.requestAccess(for: .video) { granted in
                 if granted {
                     cameraAccess = true
                     checkMicrophoneAccess()
                 } else {
                     cameraAccess = false
                     
                 }
             }
         case .restricted, .denied:
             cameraAccess = false
         case .authorized:
             cameraAccess = true
             checkMicrophoneAccess()
         @unknown default:
             break
         }
     }

     private func checkMicrophoneAccess() {
         switch AVCaptureDevice.authorizationStatus(for: .audio) {
         case .notDetermined:
             AVCaptureDevice.requestAccess(for: .audio) { granted in
                 if granted {
                    microphoneAccess = true
                 } else {
                    microphoneAccess = false
                 }
             }
         case .restricted, .denied:
             microphoneAccess = false
         case .authorized:
             microphoneAccess = true
         @unknown default:
             break
         }
     }
    
    func timerDisplayUpdated(_ display: String) {
        timerDisplay = display
    }
 }

    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl)
    }

protocol LiveCaptureVideoControllerDelegate: AnyObject {
    func didFinishRecordingVideo(at urls: [URL])
    
    func timerDisplayUpdated(_ display: String)
}

struct LiveCaptureVideoController: UIViewControllerRepresentable {
    @Binding var timerDisplay: String
    @Binding var goLive: Bool
    @Binding var showGuidlines: Bool

    let onTimerDisplayUpdated: (String) -> Void

    init(
        timerDisplay: Binding<String>,
        onTimerDisplayUpdated: @escaping (String) -> Void,
        goLive: Binding<Bool>,
        showGuidlines: Binding<Bool>
    ) {
        self._timerDisplay = timerDisplay
        self.onTimerDisplayUpdated = onTimerDisplayUpdated
        self._goLive = goLive
        self._showGuidlines = showGuidlines
    }
    
    
    
    class NetworkingManager {
        var segmentCounter: Int = 0

        func sendSegment(audioData: Data, videoData: Data, userId: String, completionHandler: @escaping (Error?) -> Void) {
            guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
                  let liveEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/live/\(userId)") else {
                print("Error: Invalid server URL or endpoint")
                return
            }
            
            var request = URLRequest(url: liveEndpoint)
            request.httpMethod = "POST"
            
            let boundary = "Boundary-\(UUID().uuidString)"
            let contentType = "multipart/form-data; boundary=\(boundary)"
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            
            // Update the segment counter
            segmentCounter += 1
            
            // Add the audio chunk to the request body
            let boundaryPrefix = "--\(boundary)\r\n"
            let audioFilename = "\(segmentCounter)_audioChunk.wav"
            let audioDisposition = "Content-Disposition: form-data; name=\"audioChunk\"; filename=\"\(audioFilename)\"\r\n"
            let audioTypeHeader = "Content-Type: audio/wav\r\n\r\n"
            
            body.append(Data(boundaryPrefix.utf8))
            body.append(Data(audioDisposition.utf8))
            body.append(Data(audioTypeHeader.utf8))
            body.append(audioData)
            body.append(Data("\r\n".utf8))
            
            // Add the video chunk to the request body
            let videoFilename = "\(segmentCounter)_videoChunk.mov"
            let videoDisposition = "Content-Disposition: form-data; name=\"videoChunk\"; filename=\"\(videoFilename)\"\r\n"
            let videoTypeHeader = "Content-Type: video/quicktime\r\n\r\n"
            
            body.append(Data(boundaryPrefix.utf8))
            body.append(Data(videoDisposition.utf8))
            body.append(Data(videoTypeHeader.utf8))
            body.append(videoData)
            body.append(Data("\r\n".utf8))
            
            let boundarySuffix = "--\(boundary)--\r\n"
            body.append(Data(boundarySuffix.utf8))
            
            request.httpBody = body
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending segments to server:", error)
                    completionHandler(error)
                } else {
                    completionHandler(nil)
                }
            }
            
            task.resume()
        }

    

    }
//
//    class AudioDataDelegate: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
//    }
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
        var parent: LiveCaptureVideoController
        var orientationObserver: NSObjectProtocol?
        var session: AVCaptureSession
        var videoDataOutput: AVCaptureVideoDataOutput?
        var audioDataOutput: AVCaptureAudioDataOutput?

        //var audioDataDelegate: AudioDataDelegate? // Create an instance of AudioDataDelegate

        var metadataOutput: AVCaptureMetadataOutput?

        var recordingStartTime: Date?
        weak var delegate: LiveCaptureVideoControllerDelegate?
        @Binding var timerDisplay: String
        @Binding var goLive: Bool
        @Binding var showGuidlines: Bool
        var isRecording: Bool = false

        var timer: Timer?
        let timerDisplayUpdateHandler: (String) -> Void
        let networkingManager = NetworkingManager() // Create an instance of the networking class

        init(
            parent: LiveCaptureVideoController,
            timerDisplay: Binding<String>,
            goLive: Binding<Bool>,
            showGuidlines: Binding<Bool>,
            onTimerDisplayUpdated: @escaping (String) -> Void // Pass the closure here
        ) {
            self.parent = parent
            self._timerDisplay = timerDisplay
            self._goLive = goLive
            self._showGuidlines = showGuidlines
            self.timerDisplayUpdateHandler = onTimerDisplayUpdated
            //self.audioDataDelegate = AudioDataDelegate()
            
    
             self.session = AVCaptureSession()
             self.timer = nil
             super.init()

            // Initialize AVAudioSession to request microphone access
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to configure audio session:", error.localizedDescription)
            }

            // Initialize AVCaptureSession
            let session = AVCaptureSession()
            //self.session = session

            // Setup video input
            if let videoDevice = AVCaptureDevice.default(for: .video), let videoInput = try? AVCaptureDeviceInput(device: videoDevice) {
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                } else {
                    print("Failed to add video input to capture session.")
                }
            } else {
                print("Failed to get video device or create video input.")
            }

            // Setup audio input
            if let audioDevice = AVCaptureDevice.default(for: .audio), let audioInput = try? AVCaptureDeviceInput(device: audioDevice) {
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                } else {
                    print("Failed to add audio input to capture session.")
                }
            } else {
                print("Failed to get audio device or create audio input.")
            }

            // Create AVCaptureVideoDataOutput
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))

            if session.canAddOutput(videoDataOutput) {
                session.addOutput(videoDataOutput)
                self.videoDataOutput = videoDataOutput
            } else {
                print("Failed to add video data output to capture session.")
            }
            
            // Configure audioOutput
            let audioDataOutput = AVCaptureAudioDataOutput()
            audioDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
            if session.canAddOutput(audioDataOutput) {
                session.addOutput(audioDataOutput)
                self.audioDataOutput = audioDataOutput
            } else {
                print("Failed to add audio data output to capture session.")
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
            }

            // Start the session
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
                if let audioDataOutput = self.audioDataOutput {
                      audioDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
                  }
               // self.startTimer()
            }
            
            orientationObserver = NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.updateVideoOrientation()
            }
        }
        deinit {
            // Remove the observer when the coordinator is deallocated
            if let observer = orientationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            timer?.invalidate()
            timer = nil

        }
        
        func startTimer() {
            print("Timer started")
            setupTimer() // Add this line to set up the timer
            recordingStartTime = Date()
            updateTimerDisplay()
        }

        
        private func setupTimer() {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateTimerDisplay()
            }
        }

        private func updateTimerDisplay() {
            guard let recordingStartTime = self.recordingStartTime else { return }

            let elapsedTime = Date().timeIntervalSince(recordingStartTime)
            let minutes = Int(elapsedTime / 60)
            let seconds = Int(elapsedTime) % 60

            let newTimerDisplay = String(format: "%02d:%02d", minutes, seconds)
            print("Updating timer display to:", newTimerDisplay)

            DispatchQueue.main.async { [weak self] in
                if self?.isRecording ?? false {
                    self?.timerDisplayUpdateHandler(newTimerDisplay) // Call the closure from the parent view
                }
            }
        }
        
        func updateVideoOrientation() {

        }


        func fileOutput(_ output: AVCaptureVideoDataOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            if let error = error {
                print("Recording finished with error: \(error)")
            } else {
                print("Recording finished.")
                print("outputFileURL:", outputFileURL)

                saveLiveToServer(url: outputFileURL) { string, error  in
                    if let error = error {
                        print("Error sending video to server:", error)
                    } else {
                        print("no errors")
                    }
                }
            }
        }

        
        func saveLiveToServer(url: URL, completionHandler: @escaping (String?, Error?) -> Void) {
            if let userId = UserDefaults.userProfile?._id {
                guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
                      let saveLiveEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/saveLive/\(userId)") else {
                    print("Error: Invalid server URL or endpoint")
                    completionHandler(nil, nil) // Call the completion handler with nil values
                    return
                }
                print("saveLiveEndpoint:", saveLiveEndpoint)
                
                var request = URLRequest(url: saveLiveEndpoint)
                request.httpMethod = "POST"
                
                let boundary = "Boundary-\(UUID().uuidString)"
                let contentType = "multipart/form-data; boundary=\(boundary)"
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
                
                var body = Data()
                
                // Add the video URL to the request body
                if let videoURLData = url.absoluteString.data(using: .utf8) {
                    body.append("--\(boundary)\r\n".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"video\"\r\n\r\n".data(using: .utf8)!)
                    body.append(videoURLData)
                    body.append("\r\n".data(using: .utf8)!)
                    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
                }
                
                request.httpBody = body
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error sending live to server:", error)
                        completionHandler(nil, error) // Call the completion handler with error
                    } else if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Live saved successfully:", responseString)
                        completionHandler(responseString, nil) // Call the completion handler with response string
                    } else {
                        print("Unable to parse response data")
                        completionHandler(nil, nil) // Call the completion handler with nil values
                    }
                }
                
                task.resume()
            }
        }
        
        var pendingAudioData: Data?
        var pendingVideoData: Data?

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard isRecording else {
                return
            }

            guard let userId = UserDefaults.userProfile?._id else {
                return
            }
            
            if output == videoDataOutput, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                if let imageData = convertImageBufferToData(imageBuffer: imageBuffer) {
                    // Store the video data
                    pendingVideoData = imageData

                    // Check if both audio and video data are ready, then send them
                    if let audioData = pendingAudioData, let videoData = pendingVideoData {
                        networkingManager.sendSegment(audioData: audioData, videoData: videoData, userId: userId) { error in
                            if let error = error {
                                print("Error sending audio and video segments to server:", error)
                            }
                        }

                        // Clear the pending data after sending
                        pendingAudioData = nil
                        pendingVideoData = nil
                    }
                } else {
                    print("Error: Failed to get image data from buffer")
                }
            } else if output == audioDataOutput {
                if let audioData = convertAudioBufferToData(audioBuffer: sampleBuffer) {
                    // Store the audio data
                    pendingAudioData = audioData

                    // Check if both audio and video data are ready, then send them
                    if let videoData = pendingVideoData, let audioData = pendingAudioData {
                        networkingManager.sendSegment(audioData: audioData, videoData: videoData, userId: userId) { error in
                            if let error = error {
                                print("Error sending audio and video segments to server:", error)
                            }
                        }

                        // Clear the pending data after sending
                        pendingAudioData = nil
                        pendingVideoData = nil
                    }
                } else {
                    print("Error: Failed to get audio data from buffer")
                }
            }
        }

        func convertImageBufferToData(imageBuffer: CVPixelBuffer) -> Data? {
            CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
            defer {
                CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
            }
            
            guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else {
                return nil
            }
            
            //let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
            
            let buffer = UnsafeBufferPointer(start: baseAddress.assumingMemoryBound(to: UInt8.self), count: height * bytesPerRow)
            return Data(buffer: buffer)
        }
        
        private func convertAudioBufferToData(audioBuffer: CMSampleBuffer) -> Data? {
            guard let blockBuffer = CMSampleBufferGetDataBuffer(audioBuffer) else {
                return nil
            }

            var length: Int = 0
            var dataPointer: UnsafeMutablePointer<Int8>? = nil
            CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)

            if let dataPointer = dataPointer {
                return Data(bytes: dataPointer, count: length)
            }

            return nil
        }



        func setSampleBufferAttachments(_ sampleBuffer: CMSampleBuffer) {
            // Get the attachments array
            guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true) as? [CFDictionary] else {
                print("Error: Failed to get sample attachments array")
                return
            }

            if let attachmentDict = attachments.first as? [String: Any] {
                var mutableAttachmentDict = attachmentDict
                //print("Attachments array:", attachments)
                //print("Attachment dictionary:", mutableAttachmentDict)

                let key = kCMSampleAttachmentKey_DisplayImmediately
                let value = kCFBooleanTrue

               // print("Setting attachment value for key:", key)

                // Set the attachment value for the specified key
                mutableAttachmentDict[key as String] = value

                //print("Attachment value set successfully")
            } else {
                print("Error: Failed to create a mutable attachment dictionary")
            }
        }

//        func printSampleBufferAttachments(_ sampleBuffer: CMSampleBuffer) {
//            if let attachmentArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [CFDictionary] {
//                for (index, attachmentDict) in attachmentArray.enumerated() {
//                    print("Sample attachments at index \(index): \(attachmentDict)")
//
//                    for (key, value) in attachmentDict {
//                        if let keyString = key as? String,
//                           let attachmentValue = value as? Bool, attachmentValue {
//                            print("Attachment Key: \(keyString)")
//                        }
//                    }
//                }
//            } else {
//                print("Error: Failed to get sample attachments array")
//            }
//        }







        func startNewRecording() {
           DispatchQueue.global(qos: .userInitiated).async {
               self.isRecording = true
               self.session.startRunning()
           }
       }
        
        func stopRecording() {
            DispatchQueue.global(qos: .userInitiated).async {
                self.isRecording = false
                self.session.stopRunning()
                self.goLive = false
                
            }
            
            // Clean up any recording-related resources
            // For example, stop capturing frames and release resources
        }
        
        func didTapGoLive() {
            if isRecording {
                stopRecording()
            } else {
                startNewRecording()
            }
        }
        
        func didTapCameraSwitch() {
            guard let videoDeviceInput = session.inputs.compactMap({ $0 as? AVCaptureDeviceInput }).first else {
                return
            }
            
            let currentPosition = videoDeviceInput.device.position
            let preferredPosition: AVCaptureDevice.Position = (currentPosition == .back) ? .front : .back
            
            if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: preferredPosition),
               let newVideoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) {
                
                session.beginConfiguration()
                session.removeInput(videoDeviceInput)
                
                if session.canAddInput(newVideoDeviceInput) {
                    session.addInput(newVideoDeviceInput)
                    
                    // Remove the current video data output
                    if let videoDataOutput = videoDataOutput {
                        session.removeOutput(videoDataOutput)
                    }
                    
                    // Create a new AVCaptureVideoDataOutput
                    let newVideoDataOutput = AVCaptureVideoDataOutput()
                    newVideoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
                    
                    if session.canAddOutput(newVideoDataOutput) {
                        session.addOutput(newVideoDataOutput)
                        videoDataOutput = newVideoDataOutput
                    } else {
                        print("Failed to add new video data output to capture session.")
                    }
                } else {
                    session.addInput(videoDeviceInput)
                }
                
                session.commitConfiguration()
            }
        }


        
        func didTapFlashlight() {
            guard let device = AVCaptureDevice.default(for: .video) else {
                return
            }
            
            if device.hasTorch {
                do {
                    try device.lockForConfiguration()
                    
                    if device.torchMode == .on {
                        device.torchMode = .off
                    } else {
                        try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                    }
                    
                    device.unlockForConfiguration()
                } catch {
                    print("Error toggling flashlight: \(error)")
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            parent: self,
            timerDisplay: $timerDisplay,
            goLive: $goLive,
            showGuidlines: $showGuidlines,
            onTimerDisplayUpdated: onTimerDisplayUpdated
        )
    }



    func makeUIViewController(context: UIViewControllerRepresentableContext<LiveCaptureVideoController>) -> LiveAVCaptureViewController {
        let controller = LiveAVCaptureViewController(coordinator: makeCoordinator())
        return controller
    }


    func updateUIViewController(_ uiViewController: LiveAVCaptureViewController, context: UIViewControllerRepresentableContext<LiveCaptureVideoController>) {
        // Update the view controller if needed
    }
}

// MARK: - Controller

struct LiveCaptureVideoViewController: UIViewControllerRepresentable {
    var coordinator: LiveCaptureVideoController.Coordinator

    init(coordinator: LiveCaptureVideoController.Coordinator) {
        self.coordinator = coordinator
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<LiveCaptureVideoViewController>) -> LiveAVCaptureViewController {
        return LiveAVCaptureViewController(coordinator: coordinator)
    }

    func updateUIViewController(_ uiViewController: LiveAVCaptureViewController, context: UIViewControllerRepresentableContext<LiveCaptureVideoViewController>) {
        // Update the view controller if needed
    }
}

class LiveAVCaptureViewController: UIViewController {
    private var coordinator: LiveCaptureVideoController.Coordinator
    private var goLiveButton: UIButton!
    private var cameraSwitchButton: UIButton!
    private var flashlightButton: UIButton!
    
    private var timer: Timer?
    private var timerDisplay = "00:00" {
        didSet {
            //print("timerDisplay updated to:", timerDisplay)
        }
    }

    private var showGuidlines: Bool = false
    private var isRecording: Bool = false {
         didSet {
             print("isRecording set to:", isRecording)
             goLiveButton.layer.backgroundColor = isRecording ? UIColor.red.cgColor : UIColor.clear.cgColor
             goLiveButton.setTitle("Live", for: .normal)
             
             if isRecording {
                 startTimer()
             } else {
                 stopTimer()
             }
         }
     }
    

    init(coordinator: LiveCaptureVideoController.Coordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds

        view.layer.addSublayer(previewLayer)

        setupButtons()

        
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if coordinator.session.canAddInput(input) {
                    coordinator.session.addInput(input)
                }
                
                if let videoDataOutput = coordinator.videoDataOutput {
                    if coordinator.session.canAddOutput(videoDataOutput) {
                        coordinator.session.addOutput(videoDataOutput)
                    }
                }
                
                previewLayer.session = coordinator.session
                
                DispatchQueue.global(qos: .userInitiated).async {
                    self.coordinator.session.startRunning()
                }
            } catch {
                print(error)
            }
        }
    }
    
    func startTimer() {
        guard timer == nil else { return } // Ensure only one timer is running
        print("Timer started")

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimerDisplay()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTimerDisplay() {
        guard let recordingStartTime = self.coordinator.recordingStartTime else { return }

        let elapsedTime = Date().timeIntervalSince(recordingStartTime)
        let minutes = Int(elapsedTime / 60)
        let seconds = Int(elapsedTime) % 60

        //print("Updating timer display to:", String(format: "%02d:%02d", minutes, seconds))
        self.timerDisplay = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func setupButtons() {
        let size = CGFloat(40)
        
        // Go Live Button
         goLiveButton = UIButton()
         goLiveButton.setTitle("Go Live", for: .normal)
         goLiveButton.setTitleColor(.white, for: .normal)
         goLiveButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
         goLiveButton.layer.borderColor = UIColor.white.cgColor
         goLiveButton.layer.borderWidth = 1
         goLiveButton.layer.cornerRadius = 5
         view.addSubview(goLiveButton)
         goLiveButton.translatesAutoresizingMaskIntoConstraints = false
         goLiveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
         goLiveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
         goLiveButton.addTarget(self, action: #selector(didTapGoLive), for: .touchUpInside)
        
        // Flashlight Button
        flashlightButton = UIButton()
        flashlightButton.setImage(UIImage(systemName: "bolt")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: size)), for: .normal)
        flashlightButton.tintColor = .white
        view.addSubview(flashlightButton)
        flashlightButton.translatesAutoresizingMaskIntoConstraints = false
        flashlightButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        flashlightButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        flashlightButton.addTarget(self, action: #selector(didTapFlashlight), for: .touchUpInside)

        // Camera Switch Button
        cameraSwitchButton = UIButton()
        cameraSwitchButton.setImage(UIImage(systemName: "camera.rotate")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: size)), for: .normal)
        cameraSwitchButton.tintColor = .white
        view.addSubview(cameraSwitchButton)
        cameraSwitchButton.translatesAutoresizingMaskIntoConstraints = false
        cameraSwitchButton.topAnchor.constraint(equalTo: flashlightButton.bottomAnchor, constant: 16).isActive = true
        cameraSwitchButton.trailingAnchor.constraint(equalTo: flashlightButton.trailingAnchor).isActive = true
        cameraSwitchButton.addTarget(self, action: #selector(didTapCameraSwitch), for: .touchUpInside)
    }
    
    @objc private func didTapRecord() {
        //isRecording.toggle()
        showGuidlines = true

    }
    
    @objc private func didTapGoLive() {
        if self.coordinator.goLive {
            isRecording = true
            goLive()
        } else {
            self.coordinator.showGuidlines = true
        }
    }
    
    @objc private func goLive() {
        if isRecording {
            coordinator.didTapGoLive()
            // Don't start the timer here
        } else {
            coordinator.stopRecording() // Stop recording
            timer?.invalidate() // Stop the timer when recording stops
            timer = nil
        }
    }
    
    @objc private func didTapCameraSwitch() {
        coordinator.didTapCameraSwitch()
    }
    
    @objc private func didTapFlashlight() {
        coordinator.didTapFlashlight()
    }
}

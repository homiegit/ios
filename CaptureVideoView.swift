import SwiftUI
import AVFoundation

struct IdentifiableURL: Identifiable, Equatable {
    var id = UUID()
    var url: URL = URL(fileURLWithPath: "")
}

struct TimerDisplay: View {
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
                    .frame(maxWidth: .infinity, alignment: .top) // Align text to the top

            }
            .padding(EdgeInsets(top: 8 - 60, leading: 8, bottom: 8, trailing: 8)) // Adjust top padding

            Spacer()
        }
    }
}


struct CaptureVideoView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    var captureVideoControllerDelegate: CaptureVideoControllerDelegate?
    @State private var showPermissionAlert = false
    @State private var cameraAccess = false
    @State private var microphoneAccess = false
    @State private var timerDisplay = "00:00"

    public var body: some View {
       ZStack {
           if cameraAccess {
               GeometryReader { geometry in
                   VStack {
                       CaptureVideoController(
                           recordedURLs: $viewRouter.recordedURLs,
                           timerDisplay: $timerDisplay,
                           onTimerDisplayUpdated: { newTimerDisplay in
                               timerDisplay = newTimerDisplay
                           }
                       )

                         .edgesIgnoringSafeArea(.all)
                           .frame(width: geometry.size.width, height: geometry.size.height)
                           .overlay(TimerDisplay(timer: $timerDisplay))
                           .onChange(of: timerDisplay) { newValue in
                               print("TimerDisplay changed to:", newValue)
                           }

                       if viewRouter.recordedURLs.count >= 1 {
                           Button(action: {
                               print("tapped")
                               cameraAccess = false
                               microphoneAccess = false
                               viewRouter.popToView("EditRecordedClipsView", atIndex: 2)
                           }) {
                               Text("Next")
                                   .font(.system(size: 34))
                                   .padding(10)
                                   .border(Color.white, width: 1)
                                   .background(Color.black)
                                   .foregroundColor(Color.white)
                                   .alignmentGuide(.trailing) { _ in
                                       geometry.size.width // Align to the right edge of the screen
                                   }
                                   .alignmentGuide(.bottom) { _ in
                                       geometry.size.height // Align to the bottom of the screen
                                   }
                           }
                           .padding(EdgeInsets( top: -100, leading: 260, bottom: 0, trailing: 0))

                       }

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

protocol CaptureVideoControllerDelegate: AnyObject {
    func didFinishRecordingVideo(at urls: [URL])
    
    func timerDisplayUpdated(_ display: String)
}

struct CaptureVideoController: UIViewControllerRepresentable {
    var recordedURLs: Binding<[IdentifiableURL]>
    @Binding var timerDisplay: String // Change the type to Binding<String>

    let onTimerDisplayUpdated: (String) -> Void // Closure to handle timer display update

    init(
        recordedURLs: Binding<[IdentifiableURL]>,
        timerDisplay: Binding<String>,
        onTimerDisplayUpdated: @escaping (String) -> Void
    ) {
        self.recordedURLs = recordedURLs
        self._timerDisplay = timerDisplay
        self.onTimerDisplayUpdated = onTimerDisplayUpdated
    }
    
    class Coordinator: NSObject, AVCaptureFileOutputRecordingDelegate {
        var parent: CaptureVideoController
        var recordedURLs: Binding<[IdentifiableURL]>
        var orientationObserver: NSObjectProtocol?
        var session: AVCaptureSession
        var movieOutput: AVCaptureMovieFileOutput
        var recordingStartTime: Date?
        weak var delegate: CaptureVideoControllerDelegate?
        @Binding var timerDisplay: String
        var isRecording: Bool = false

        var timer: Timer?
        let timerDisplayUpdateHandler: (String) -> Void

        init(
            parent: CaptureVideoController,
            recordedURLs: Binding<[IdentifiableURL]>,
            timerDisplay: Binding<String>,
            onTimerDisplayUpdated: @escaping (String) -> Void // Pass the closure here
        ) {
            self.parent = parent
            self.recordedURLs = recordedURLs
            self._timerDisplay = timerDisplay
            self.timerDisplayUpdateHandler = onTimerDisplayUpdated

             self.session = AVCaptureSession()
             self.movieOutput = AVCaptureMovieFileOutput()
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
            self.session = session

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

            // Setup movie output
            let movieOutput = AVCaptureMovieFileOutput()
            self.movieOutput = movieOutput

            if let connection = movieOutput.connection(with: .audio) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }

            if session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
            } else {
                print("Failed to add movie output to capture session.")
            }

            // Start the session
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
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
            if let connection = movieOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    let deviceOrientation = UIDevice.current.orientation
                    switch deviceOrientation {
                    case .portrait:
                        connection.videoOrientation = .portrait
                    case .portraitUpsideDown:
                        connection.videoOrientation = .portraitUpsideDown
                    case .landscapeLeft:
                        connection.videoOrientation = .landscapeRight
                    case .landscapeRight:
                        connection.videoOrientation = .landscapeLeft
                    default:
                        // Keep the current orientation if the device orientation is face up or face down
                        break
                    }
                }
            }
        }
    
        func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
            print("Recording started.")
            DispatchQueue.main.async {
                self.isRecording = true // Update recording state
                self.startTimer() // Start the timer
            }
        }
        
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            if let error = error {
                print("Recording finished with error: \(error)")
            } else {
                print("Recording finished.")
                print("outputFileURL:", outputFileURL)

                recordedURLs.wrappedValue.append(IdentifiableURL(url: outputFileURL))

                DispatchQueue.main.async {
                    self.isRecording = false
                    self.timer?.invalidate()
                    self.timer = nil
                    self.delegate?.timerDisplayUpdated(self.timerDisplay)
                }
            }
        }


        func didTapRecord() {
            print("Shutter button tapped.")
            toggleRecording()

            if isRecording {
                startTimer()
            } else {
                timer?.invalidate()
                timer = nil
            }
        }


        func toggleRecording() {
            if movieOutput.isRecording {
                print("stopped recording")
                movieOutput.stopRecording()
                session.stopRunning()

                recordingStartTime = nil
                isRecording = false // Update isRecording state
                timer?.invalidate() // Stop the timer
                timer = nil
                
                startNewRecording()
                
            } else {
                print("recording")
                let tempDir = NSTemporaryDirectory()
                let videoURL = URL(fileURLWithPath: tempDir).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")

                DispatchQueue.main.async {
                    self.movieOutput.startRecording(to: videoURL, recordingDelegate: self)
                    self.recordingStartTime = Date()
                    self.isRecording = true // Update isRecording state
                    
                    self.setupTimer() // Initialize the timer
                }
            }
        }


        func startNewRecording() {
           DispatchQueue.global(qos: .userInitiated).async {
               self.session.startRunning()
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
                    
                    // Update AVCaptureMovieFileOutput with the new video input
                    session.removeOutput(movieOutput)
                    let newMovieOutput = AVCaptureMovieFileOutput()
                    if session.canAddOutput(newMovieOutput) {
                        session.addOutput(newMovieOutput)
                        movieOutput = newMovieOutput
                    } else {
                        print("Failed to add new movie output to capture session.")
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
            recordedURLs: recordedURLs,
            timerDisplay: $timerDisplay,
            onTimerDisplayUpdated: onTimerDisplayUpdated
        )
    }



    func makeUIViewController(context: UIViewControllerRepresentableContext<CaptureVideoController>) -> AVCaptureViewController {
        let controller = AVCaptureViewController(coordinator: makeCoordinator())
        return controller
    }


    func updateUIViewController(_ uiViewController: AVCaptureViewController, context: UIViewControllerRepresentableContext<CaptureVideoController>) {
        // Update the view controller if needed
    }
}

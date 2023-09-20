import SwiftUI
import AVFoundation
import Photos

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
//                        .onChange(of: timerDisplay) { newValue in
//                            print("TimerDisplay changed to:", newValue)
//                        }

                       if viewRouter.recordedURLs.count >= 1 {
                           Button(action: {
                               print("tapped")
                               cameraAccess = false
                               microphoneAccess = false
                               viewRouter.popToView("EditRecordedClipsView", atIndex: viewRouter.path.count)
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

        var videoConnection:AVCaptureConnection?

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
            if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front), let videoInput = try? AVCaptureDeviceInput(device: videoDevice) {
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
                    connection.videoOrientation = .landscapeLeft
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
        
        enum MirrorVideoErrors: Error {
            case someError
            case anotherError(description: String)
            // Add more cases as needed
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
            
            var videoConnection: AVCaptureConnection? = nil
            for connection in connections {
                for port in connection.inputPorts {
                    if port.mediaType == .video {
                        videoConnection = connection
                        break
                    }
                }
                if videoConnection != nil {
                    break
                }
            }

            // Check if the video connection exists and whether it supports video mirroring
            if let videoConnection = videoConnection, videoConnection.isVideoMirroringSupported {
                videoConnection.isVideoMirrored = true // Enable video mirroring for front camera
                print("isvideomirrored true while recording")

            }
            
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
                
                DispatchQueue.main.async { [weak self] in
                    self?.recordedURLs.wrappedValue.append(IdentifiableURL(url: outputFileURL))
                }
                
//                let urls = recordedURLs.wrappedValue.map { $0.url }
//                urls.append(contentsOf: outputFileURL)
//
//                DispatchQueue.main.async { [weak self] in
//                    let identifiableURLs = urls.map { IdentifiableURL(url: $0) }
//                    self?.recordedURLs.wrappedValue.append(contentsOf: identifiableURLs)
//                }

//                // Extract the URLs from recordedURLs
//                let urls = recordedURLs.wrappedValue.map { $0.url }
//
//                Task {
//                    do {
//                        let mirroredURLs = try await mirrorVideo(inputURL: outputFileURL, existingURLs: urls)
//
//                        DispatchQueue.main.async { [weak self] in
//                            // Handle the mirrored URLs on the main queue
//                            let identifiableURLs = mirroredURLs.map { IdentifiableURL(url: $0) }
//                            self?.recordedURLs.wrappedValue.append(contentsOf: identifiableURLs)
//                            self?.delegate?.timerDisplayUpdated(self?.timerDisplay ?? "")
//                        }
//                    } catch {
//                        print("Error in mirrorVideo: \(error)")
//                        // Handle the error here, such as displaying an alert to the user
//                    }
//                }
            }
        }

        func mirrorVideo(inputURL: URL, existingURLs: [URL]?) async throws -> [URL] {
            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Error getting documents directory URL")
                throw MirrorVideoErrors.someError // You should define and throw an appropriate error type here
            }

            let videoAsset: AVAsset = AVAsset(url: inputURL)
            let clipVideoTrack = try await videoAsset.loadTracks(withMediaType: AVMediaType.video).first! as AVAssetTrack

            let composition = AVMutableComposition()
            composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())

            let videoComposition = AVMutableVideoComposition()
            videoComposition.renderSize = try await CGSize(width: clipVideoTrack.load(.naturalSize).width, height: clipVideoTrack.load(.naturalSize).height)
            videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)

            let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeMakeWithSeconds(60, preferredTimescale: 30))
            var transform: CGAffineTransform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            transform = try await transform.translatedBy(x: -clipVideoTrack.load(.naturalSize).width, y: 0.0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
            transform = try await transform.translatedBy(x: 0.0, y: -clipVideoTrack.load(.naturalSize).width)

            transformer.setTransform(transform, at: CMTime.zero)

            instruction.layerInstructions = [transformer]
            videoComposition.instructions = [instruction]

            // Export

            let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPreset640x480)!
            let fileName = UUID().uuidString.appending("mirrored.mov")
            let filePath = documentsURL.appendingPathComponent(fileName)
            let croppedOutputFileUrl = filePath
            exportSession.outputURL = croppedOutputFileUrl
            exportSession.outputFileType = AVFileType.mp4

            await exportSession.export()

            if exportSession.status == .completed {
                var outputURLs = existingURLs ?? []
                outputURLs.append(croppedOutputFileUrl)
                return outputURLs
            } else if exportSession.status == .failed {
                print("Export failed - \(String(describing: exportSession.error))")
                throw MirrorVideoErrors.someError // You should define and throw an appropriate error type here
            }

            throw MirrorVideoErrors.someError // Handle any other errors and throw an appropriate error type
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
            
            if let videoDevice = AVCaptureDevice.default(preferredPosition == .front ? .builtInWideAngleCamera : .builtInUltraWideCamera, for: .video, position: preferredPosition),
               let newVideoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) {
                
                session.beginConfiguration()
                session.removeInput(videoDeviceInput)
                session.removeOutput(movieOutput)
                
                if session.canAddInput(newVideoDeviceInput) {
                    session.addInput(newVideoDeviceInput)
                    
                    
                    // Update AVCaptureMovieFileOutput with the new video input
                    let newMovieOutput = AVCaptureMovieFileOutput()
                    if session.canAddOutput(newMovieOutput) {
                    
                        session.addOutput(newMovieOutput)
                        movieOutput = newMovieOutput
                        
                    } else {
                        print("Failed to add new movie output to capture session.")
                    }
                } else {
                    print("can't add newVideoDeviceInput")
                    session.addInput(videoDeviceInput)
                    didTapCameraSwitch()
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
// capturevideocontroller.swift

struct CaptureVideoViewController: UIViewControllerRepresentable {
    var coordinator: CaptureVideoController.Coordinator

    init(coordinator: CaptureVideoController.Coordinator) {
        self.coordinator = coordinator
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<CaptureVideoViewController>) -> AVCaptureViewController {
        return AVCaptureViewController(coordinator: coordinator)
    }

    func updateUIViewController(_ uiViewController: AVCaptureViewController, context: UIViewControllerRepresentableContext<CaptureVideoViewController>) {
        // Update the view controller if needed
    }
}

class AVCaptureViewController: UIViewController {
    var coordinator: CaptureVideoController.Coordinator
    private var shutterButton: UIButton!
    private var cameraSwitchButton: UIButton!
    private var flashlightButton: UIButton!
    private var viewButton: UIButton!
    private var showViews: Bool = false
    private var imageView: UIImageView?
    private var showImages: Bool = false
    private var selectedImages: [UIImage]?
    private var assets: [PHAsset] = []

    private var currentIndex: Int = 0
    private var customImagePicker: CustomImagePickerController?

    
    var currentView: String = "frontCamera"
    
    private var imagesButton: UIButton!
    private var hideCameraView: UIButton!
    private var showCameraView: UIButton!


    private var timer: Timer?
    private var timerDisplay = "00:00" {
        didSet {
            //print("timerDisplay updated to:", timerDisplay)
        }
    }
    
    private var isRecording: Bool = false {
         didSet {
             print("isRecording set to:", isRecording)
             if isRecording {
                 startTimer()
             } else {
                 stopTimer()
             }
         }
     }
    
    init(coordinator: CaptureVideoController.Coordinator) {
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
                
                if coordinator.session.canAddOutput(coordinator.movieOutput) {
                    coordinator.session.addOutput(coordinator.movieOutput)
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
    
    private func startTimer() {
        guard timer == nil else { return } // Ensure only one timer is running
        print("Timer started")

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimerDisplay()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func stopTimer() {
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

//    private func showCameraView() {
//        // Remove the image view if it exists
//        imageView?.removeFromSuperview()
//    }
    
//    private func presentImagePicker() {
//        let imagePicker = UIImagePickerController()
//        imagePicker.sourceType = .photoLibrary
//        imagePicker.delegate = self
//        imagePicker.allowsEditing = false
//        imagePicker.mediaTypes = ["public.image"]
//        imagePicker.allowsMultipleSelection = true
//        present(imagePicker, animated: true, completion: nil)
//    }

//    private func showImageView(image: UIImage) {
//        // Create an image view and add it to the view
//        DispatchQueue.main.async {
//            self.imageView = UIImageView(frame: self.view.bounds)
//            self.imageView?.contentMode = .scaleToFill
//            self.imageView?.image = image // Replace with the actual image name
//            self.view.addSubview(self.imageView!)
//        }
//
//        // Add a pan gesture recognizer
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//        imageView?.addGestureRecognizer(panGesture)
//    }
//
//    private func showNextImage() {
//        guard let imageView = imageView else { return }
//
//        if let selectedImages = selectedImages, let currentIndex = selectedImages.firstIndex(of: imageView.image ?? UIImage()) {
//            let nextIndex = currentIndex + 1
//            if nextIndex < selectedImages.count {
//                imageView.image = selectedImages[nextIndex]
//            }
//        }
//    }
//
//    private func showPreviousImage() {
//        guard let imageView = imageView else { return }
//
//        if let selectedImages = selectedImages, let currentIndex = selectedImages.firstIndex(of: imageView.image ?? UIImage()) {
//            let previousIndex = currentIndex - 1
//            if previousIndex < selectedImages.count {
//                imageView.image = selectedImages[previousIndex]
//            }
//        }
//    }
    
    private func setupButtons() {
        let size = CGFloat(40)
        
        // Shutter Button
        shutterButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        shutterButton.layer.cornerRadius = 50
        shutterButton.layer.backgroundColor = isRecording ? UIColor.red.cgColor : UIColor.clear.cgColor
        shutterButton.layer.borderWidth = 3
        shutterButton.layer.borderColor = UIColor.white.cgColor
        view.addSubview(shutterButton)
        shutterButton.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height - 100)
        shutterButton.addTarget(self, action: #selector(didTapRecord), for: .touchUpInside)
        
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
        
        // Toggle Camera View
        viewButton = UIButton()
        viewButton.setImage(UIImage(systemName: currentView == "frontCamera" ? "person.fill.viewfinder" : currentView == "image" ? "camera.viewfinder" : "viewfinder")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: size)), for: .normal)
        viewButton.tintColor = .white
        view.addSubview(viewButton)
        viewButton.translatesAutoresizingMaskIntoConstraints = false
        viewButton.topAnchor.constraint(equalTo: cameraSwitchButton.bottomAnchor, constant: 16).isActive = true
        viewButton.trailingAnchor.constraint(equalTo: cameraSwitchButton.trailingAnchor).isActive = true
        viewButton.addTarget(self, action: #selector(didTapViewButton), for: .touchUpInside)
        
        if showViews {
            viewsButtons()
        }
    }
    
    private func viewsButtons() {
        let size = CGFloat(40)
        
        // Images button
        imagesButton = UIButton()
        imagesButton.setImage(UIImage(systemName: "photo.on.rectangle")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: size)), for: .normal)
        imagesButton.tintColor = .white
        view.addSubview(imagesButton)
        imagesButton.translatesAutoresizingMaskIntoConstraints = false
        imagesButton.topAnchor.constraint(equalTo: viewButton.bottomAnchor, constant: 16).isActive = true
        imagesButton.trailingAnchor.constraint(equalTo: viewButton.trailingAnchor).isActive = true
        imagesButton.addTarget(self, action: #selector(didTapImagesButton), for: .touchUpInside)
        
    }
    
    @objc private func didTapRecord() {
        isRecording.toggle()
        setupButtons()

        if isRecording {
            coordinator.didTapRecord()
            // Don't start the timer here
        } else {
            coordinator.toggleRecording() // Stop recording
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
    
    @objc private func didTapViewButton() {
        //coordinator.didTapViewButton()
        showViews.toggle()
        setupButtons()
        // Check the value of currentView and toggle between camera and image view
    }
    
    @objc private func didTapImagesButton() {
        // Initialize the custom image picker
        customImagePicker = CustomImagePickerController()
        
        // Set a callback closure to handle selected images
        customImagePicker?.didSelectImagesCallback = { [weak self] selectedImages in
            // Handle the selected images in your AVCaptureViewController
            self?.selectedImages = selectedImages
            self?.imageView?.removeFromSuperview() // Remove any existing image view
            self?.currentIndex = 0 // Reset the index to show the first selected image
            self?.showSelectedImage() // Display the selected image
            self?.setupButtons()
            print("selectedImages:", selectedImages)
        }
        
        // Present the custom image picker
        if let customImagePicker = customImagePicker {
            present(customImagePicker, animated: true, completion: nil)
        }
    }
    
    // Function to display the selected image
    private func showSelectedImage() {
        if let selectedimages = selectedImages{
            guard currentIndex >= 0, currentIndex < selectedimages.count else {
                print("index out of range:", currentIndex, "of", selectedimages)
                return
            }
            
            let selectedImage = selectedimages[currentIndex]
            
            if let imageView = imageView {
                imageView.removeFromSuperview()
            }
            
            // Create an image view and add it to the view
            imageView = UIImageView(frame: view.bounds)
            imageView?.contentMode = .scaleToFill
            imageView?.image = selectedImage
            imageView?.isUserInteractionEnabled = true
            // Add a pan gesture recognizer for navigation
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            
            imageView?.addGestureRecognizer(panGesture)
            
            //panGesture.require(toFail: otherGestureRecognizer)

            view.addSubview(imageView!)
            
            
            self.currentView = "image"
        }
    }
    
    // Handle pan gesture for navigating between selected images
    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let imageView = imageView else { return }
        
        let translation = recognizer.translation(in: imageView)
        print("translation", translation)
        print("state:", recognizer.state)

        switch recognizer.state {
        case .began:
            // Handle the beginning of the pan gesture if needed
            break
        case .changed:
            break
            // Handle the ongoing drag for navigation

        case .ended:
            // Handle the end of the pan gesture if needed
            if translation.x < -50 {
                // Swipe left: Navigate to the next image
                currentIndex += 1
            } else if translation.x > 50 {
                // Swipe right: Navigate to the previous image
                currentIndex -= 1
            }
            showSelectedImage()
            setupButtons()
            break
        default:
            break
        }
    }

}

class CustomImagePickerController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var selectedImages: [UIImage] = []
    private var assets: [PHAsset] = []
    private var collectionView: UICollectionView!
    var didSelectImagesCallback: (([UIImage]) -> Void)?
    private var doneButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        let status = PHPhotoLibrary.authorizationStatus()
        print("status:", status.rawValue)

        // Request photo library access
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            if status == .authorized {
                // Access granted, load images
                self?.loadImages()
            } else {
                print("not authorized")
            }
        }

        setupCollectionView()
        setupDoneButton()
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical

        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: "ImageCell")
        collectionView.backgroundColor = .white
        collectionView.allowsSelection = true // Allow selection of cells
        collectionView.allowsMultipleSelection = true // Allow multiple cell selection

        self.view.addSubview(collectionView)
    }

    private func setupDoneButton() {
        doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
        ])
    }

    @objc private func doneButtonTapped() {
        // Call the didSelectImagesCallback with the selectedImages
        self.didSelectImagesCallback?(self.selectedImages)

        // Dismiss the photo picker
        self.dismiss(animated: true, completion: nil)
        
    }

    private func loadImages() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assetsFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        // Convert the fetch result to an array
        assets = assetsFetchResult.objects(at: IndexSet(integersIn: 0..<assetsFetchResult.count))

        if assets.count > 0 {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        } else {
            // Handle the case where no images are available
        }
    }

    // UICollectionViewDataSource methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCollectionViewCell
        let asset = assets[indexPath.item]

        // Request image data from the asset and display it in the cell
        PHImageManager.default().requestImage(for: asset, targetSize: cell.imageView.bounds.size, contentMode: .aspectFill, options: nil) { (image, _) in
            cell.imageView.image = image
        }

        // Check if the image is selected and set the cell's selection state accordingly
        if selectedImages.contains(where: { $0 == cell.imageView.image }) {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }

        return cell
    }

    // UICollectionViewDelegate methods
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = assets[indexPath.item]

        // Check if the image is already in selectedImages
        if selectedImages.contains(where: { $0 == asset }) {
            // Image is already selected, remove it
            if let index = selectedImages.firstIndex(where: { $0 == asset }) {
                selectedImages.remove(at: index)
            }
        } else {
            // Image is not in selectedImages, add it
            if let cell = collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell,
               let image = cell.imageView.image {
                selectedImages.append(image)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        // Handle deselection if needed (optional)
    }

    // UICollectionViewDelegateFlowLayout methods
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Adjust the cell size based on the number of columns you want to display
        let numberOfColumns: CGFloat = 3
        let cellSpacing: CGFloat = 5
        let totalSpacing = (numberOfColumns - 1) * cellSpacing
        let cellWidth = (collectionView.bounds.width - totalSpacing) / numberOfColumns
        return CGSize(width: cellWidth, height: cellWidth)
    }

    // Function to set the callback closure for selected images
    func setDidSelectImagesCallback(callback: (([UIImage]) -> Void)?) {
        self.didSelectImagesCallback = callback
    }
}

class ImageCollectionViewCell: UICollectionViewCell {
    // Create an image view to display the image
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    // Override the initializer to set up the cell
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Add the image view to the cell's content view and set up constraints
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

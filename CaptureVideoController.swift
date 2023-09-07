import SwiftUI
import AVFoundation

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
    
    private var timer: Timer?
    private var timerDisplay = "00:00" {
        didSet {
            print("timerDisplay updated to:", timerDisplay)
        }
    }

    
    private var isRecording: Bool = false {
         didSet {
             print("isRecording set to:", isRecording)
             shutterButton.layer.backgroundColor = isRecording ? UIColor.red.cgColor : UIColor.clear.cgColor
             
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

        print("Updating timer display to:", String(format: "%02d:%02d", minutes, seconds))
        self.timerDisplay = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func setupButtons() {
        let size = CGFloat(40)
        
        // Shutter Button
        shutterButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        shutterButton.layer.cornerRadius = 50
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
    }
    
    @objc private func didTapRecord() {
        isRecording.toggle()

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
}


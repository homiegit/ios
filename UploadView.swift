import SwiftUI
import _PhotosUI_SwiftUI
import AVKit

struct SelectedVideo {
    var uri: String
    var fileName: String
    var type: String
}

struct VideoPickerTransferable: Transferable {
    let videoURL: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { exportingFile in
            return .init(exportingFile.videoURL)
        } importing: { ReceivedTransferredFile in
            let originalFile = ReceivedTransferredFile.file
            
            // Generate a unique UUID for the copied file name
            let uniqueID = UUID().uuidString
            let copiedFile = URL.documentsDirectory.appendingPathComponent("\(uniqueID).mov")
            
            if FileManager.default.fileExists(atPath: copiedFile.path()) {
                try FileManager.default.removeItem(at: copiedFile)
            }
            
            try FileManager.default.copyItem(at: originalFile, to: copiedFile)
            
            return .init(videoURL: copiedFile)
        }
    }
}

struct UploadView: View {
    @EnvironmentObject var viewRouter: ViewRouter {
        didSet {
            print("viewRouter in upload:", viewRouter)
        }
    }

    @State private var currentIndex: [Int] = []
    @State private var showVideoPicker: Bool = false
    @State private var isLoggedIn: Bool = false
    @State var recordedClips: [URL]? = nil
    @State private var isVideoLoading: Bool = false
    @State private var isDoneAppending: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if !isDoneAppending {
                VStack {
                    Button(action: {
                        if UserDefaults.userProfile != nil && UserDefaults.userProfile?._id != "" {
                            viewRouter.popToView("LiveCaptureVideoView", atIndex: 1)
                        } else {
                            viewRouter.popToView("SignInView", atIndex: 1)

                        }
                    }) {
                        Text("Go Live")
                            .foregroundColor(.white)
                            .font(.system(size: 34))
                            .padding(15)
                            .border(Color.white, width: 1)
                    }
                    .padding(.bottom, 20)

                        Button(action: {
                            if UserDefaults.userProfile != nil && UserDefaults.userProfile?._id != "" {
                                viewRouter.popToView("CaptureVideoView", atIndex: 1)
                            } else {
                                viewRouter.popToView("SignInView", atIndex: 1)

                            }
                        }) {
                            Text("Record")
                                .foregroundColor(.white)
                                .font(.system(size: 34))
                                .padding(15)
                                .border(Color.white, width: 1)
                        }
                        
                        .padding(.bottom, 20)
                        Button(action: {
                            if UserDefaults.userProfile != nil && UserDefaults.userProfile?._id != "" {
                                
                                viewRouter.showVideoPicker = true
                            } else {
                                viewRouter.popToView("SignInView", atIndex: 1)

                            }
                        }) {
                            Text("Import Video")
                                .foregroundColor(.white)
                                .font(.system(size: 34))
                                .padding(15)
                                .border(Color.white, width: 1)
                            
                        }
                        .padding(.bottom, 20)
                        .photosPicker(isPresented: $viewRouter.showVideoPicker, selection: $viewRouter.selectedVideos, maxSelectionCount: 10, matching: .videos)
                        
                        .onChange(of: viewRouter.selectedVideos) { newValue in
                            if !newValue.isEmpty {
                                print("newValue:", newValue)
                                isVideoLoading = true

                                Task {
                                    do {
                                        var updatedURLs: [URL] = viewRouter.selectedVideoURLs ?? []
                                        
                                        for selectedVideo in newValue {
                                            print("selectedVideo:", selectedVideo)
                                            if let selectedMovie = try await selectedVideo.loadTransferable(type: VideoPickerTransferable.self) {
                                                print("selectedMovie:", selectedMovie)
                                                if !updatedURLs.contains(selectedMovie.videoURL) {
                                                    updatedURLs.append(selectedMovie.videoURL)
                                                }
                                            } else {
                                                print("Error loadTransferable")
                                            }
                                        }
                                        
                                        DispatchQueue.main.async {
                                            viewRouter.selectedVideoURLs = updatedURLs
                                            viewRouter.popToView("EditRecordedClipsView", atIndex: 1)
                                            isVideoLoading = false
                                            isDoneAppending = true
                                        }
                                    } catch {
                                        print("Error loading transferable:", error)
                                        isVideoLoading = false
                                    }
                                }
                            }
                        }


//                        Button(action: {
//                            if UserDefaults.userProfile != nil && UserDefaults.userProfile?._id != "" {
//                                viewRouter.popToView("ComposeWord", atIndex: 1)
//                            } else {
//
//                                viewRouter.popToView("SignInView", atIndex: 1)
//                            }
//
//                        }) {
//                            Text("Compose Word")
//                                .foregroundColor(.white)
//                                .font(.system(size: 34))
//                                .padding(15)
//                                .border(Color.white, width: 1)
//
//                        }
//                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            if let userProfile = UserDefaults.userProfile {
                print("User Profile: \(userProfile)")
            } else {
                print("User Profile not set.")
            }
            isDoneAppending = false
        }
    }
}


struct PreviewLayerView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        previewLayer.frame = uiView.bounds
    }
}



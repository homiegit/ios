import SwiftUI
import MobileCoreServices
import PhotosUI

struct VideoPicker: UIViewControllerRepresentable {
    @EnvironmentObject var viewRouter: ViewRouter
    @Binding var selectedVideos: [SelectedVideo]
    var isAlertPresented = false

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker

        init(_ parent: VideoPicker) {
            self.parent = parent
        }

        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            for result in results {
                let itemProvider = result.itemProvider
                if itemProvider.hasItemConformingToTypeIdentifier("public.movie") {
                    itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { [self] (url, error) in
                        if let videoURL = url {
                            print("Video URL:", videoURL)
                            
                            // You can directly use 'videoURL' here without copying
                            let fileName = (videoURL.lastPathComponent as NSString).deletingPathExtension
                            if let mimeType = itemProvider.registeredTypeIdentifiers.first {
                                print("MIME Type:", mimeType)
                                
                                let selectedVideo = SelectedVideo(uri: videoURL.absoluteString, fileName: fileName, type: mimeType)
                                print("Selected Video:", selectedVideo)
                                
                                //let id = UUID()
                                //let identifiableURL = IdentifiableURL(id: id, url: videoURL)
                                
                                DispatchQueue.main.async {
                                    self.parent.selectedVideos.append(selectedVideo)
                                    //self.parent.viewRouter.recordedURLs.append(identifiableURL)
                                    print("Recorded URLs:", self.parent.viewRouter.recordedURLs)
                                    
                                    self.parent.viewRouter.showVideoPicker = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        // Check photo gallery permissions here
        var mutableIsAlertPresented = self.isAlertPresented // Capture a mutable copy

        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if !mutableIsAlertPresented { // Check if alert is not already presented
                    mutableIsAlertPresented = true // Mark the alert as being presented
                    
                    switch status {
                    case .authorized:
                        print("authorized")
                        
                        viewRouter.showVideoPicker = true
                    case .notDetermined:
                        print("notDetermined")
                        
                        viewRouter.showVideoPicker = false
                        presentPhotoGalleryAccessAlert()
                        
                    case .restricted, .denied:
                        print("restricted or denied")
                        
                        //isVideoPickerPresented = false
                        presentPhotoGalleryAccessAlert()
                        
                    case .limited:
                        print("limited")
                        
                        presentPhotoGalleryAccessAlert()
                        
                    @unknown default:
                        print("unknown")
                        
                        presentPhotoGalleryAccessAlert()
                        
                    }
                }
            
            }
        }

        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 0
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }


    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // Update UI if needed
    }
    
    private func presentPhotoGalleryAccessAlert() {
        let alert = UIAlertController(
            title: "Photo Gallery Access",
            message: "This app requires access to your photo gallery to select videos. Please grant permission in Settings.",
            preferredStyle: .alert
        )
        
        // Open settings action
        let openSettingsAction = UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
        
        alert.addAction(openSettingsAction)
        
        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.viewRouter.showVideoPicker = false
        }
        
        alert.addAction(cancelAction)
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true, completion: nil)
            }
        }
    }

}

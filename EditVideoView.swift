//import SwiftUI
//import AVKit
//import AVFoundation
//
//struct EditVideoView: View {
//    @Binding var selectedVideos: [SelectedVideo]
//    @State var isPlaying: Bool = true
//
//    @State private var concatenatedVideo: URL?
//
////    @StateObject private var viewModel: VideoViewModel = VideoViewModel(selectedVideos: [], currentIndex: 0)
//
//    @ObservedObject var viewModel: VideoViewModel
//
//    var body: some View {
//        ZStack {
//            VStack {
//                Button(action: {
//                    isPlaying.toggle()
//                }) {
////                    EditVideoPlayer(urls: selectedVideos.map { URL(string: $0.uri)! },
////                        currentIndex: $viewModel.currentIndex)
////                        .environmentObject(viewModel) // Pass the viewModel to the EditVideoPlayer as an environment object
////
////                           .fullScreenHeight()
////                           .cornerRadius(0)
////                           .padding(.top, 0)
////                           .frame(width: UIScreen.main.bounds.width / 1.5, height: UIScreen.main.bounds.height / 1.5)
////
////                   .fullScreenHeight()
////                   .cornerRadius(0)
////                   .padding(.top, 0)
////                   .frame(width: UIScreen.main.bounds.width / 1.5, height: UIScreen.main.bounds.height / 1.5)
//                }
//
//                HStack {
//                   ForEach(selectedVideos.indices, id: \.self) { index in
//                       VideoThumbnailView(videoURI: selectedVideos[index].uri, viewModel: viewModel)
//
//                           .foregroundColor(viewModel.currentIndex == index ? .blue : .white)
//                           .padding(8)
//                   }
//               }
//                .frame(maxWidth: .infinity, alignment: .trailing)
//                .padding(.horizontal)
//
//                NavigationLink(destination: PostVideo(url: concatenatedVideo ?? URL(string: selectedVideos[0].uri))){
//                    Text("Next")
//                        .foregroundColor(Color.white)
//                        .border(Color.white, width: 2)
//                }
//            }
//        }
//        .padding(.bottom, 20)
//        .buttonStyle(NoHighlightButtonStyle())
//        .background(Color.black)
//    }
//}
//
//struct VideoThumbnailView: View {
//    let videoURI: String
//    @ObservedObject var viewModel: VideoViewModel
//
//    var body: some View {
//        ZStack(alignment: .leading) {
//            HStack(spacing: 0) {
//                Image(uiImage: generateThumbnail(from: URL(string: videoURI)!))
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: 50, height: 50)
//                    .cornerRadius(8)
//
//                if viewModel.currentIndex == viewModel.videos.firstIndex(where: { $0.uri == videoURI }) {
//                    ForEach(1..<7) { _ in
//                        Image(uiImage: generateThumbnail(from: URL(string: videoURI)!))
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .frame(width: 50, height: 50)
//                            .cornerRadius(8)
//                    }
//                }
//            }
//            .gesture(DragGesture()
//                .onChanged { value in
//                    viewModel.updateVideoTrim(at: viewModel.currentIndex, dragValue: value.translation.width)
//                }
//                .onEnded { value in
//                    viewModel.endVideoTrim(at: viewModel.currentIndex, dragValue: value.translation.width)
//                }
//            )
//
//            // Yellow bars on the edges when thumbnail is pressed
//            if viewModel.isThumbnailSelected(at: viewModel.currentIndex) {
//                RoundedRectangle(cornerRadius: 8)
//                    .foregroundColor(.yellow)
//                    .frame(width: 4)
//                    .offset(x: -2)
//                RoundedRectangle(cornerRadius: 8)
//                    .foregroundColor(.yellow)
//                    .frame(width: 4)
//                    .offset(x: 50 * 7 - 2)
//            }
//        }
//    }
//
//    func generateThumbnail(from videoURL: URL) -> UIImage {
//        print("Generating thumbnail for URL: \(videoURL)")
//
//          let asset = AVAsset(url: videoURL)
//          let imageGenerator = AVAssetImageGenerator(asset: asset)
//          imageGenerator.appliesPreferredTrackTransform = true
//
//          let time = CMTime(seconds: 0, preferredTimescale: 1)
//          var thumbnailImage: UIImage = UIImage()
//
//          do {
//              let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
//              thumbnailImage = UIImage(cgImage: cgImage)
//          } catch {
//              print("Error generating thumbnail: \(error.localizedDescription)")
//          }
//
//          return thumbnailImage
//      }
//}
//class VideoViewModel: ObservableObject {
//    @Published var videos: [SelectedVideo]
//    @Published var currentIndex: Int = 0 {
//        didSet {
//            print("currentIndex set to", currentIndex as Any)
//        }
//    }
//
//    @Published var isMuted: Bool = false
//
//    init(selectedVideos: [SelectedVideo], currentIndex: Int) {
//        self.videos = selectedVideos
//        self.currentIndex = currentIndex
//    }
//
//    struct TrimValues {
//        var trimStart: CGFloat = 0
//        var trimEnd: CGFloat = 1
//    }
//
//    static var trimValues: [TrimValues] = Array(repeating: TrimValues(), count: 7)
//
//    func isThumbnailSelected(at index: Int) -> Bool {
//        return currentIndex == index
//    }
//
//    func updateVideoTrim(at index: Int, dragValue: CGFloat) {
//        if currentIndex == index {
//            let totalWidth = CGFloat(50 * VideoViewModel.trimValues.count)
//            let trimStart = VideoViewModel.trimValues[currentIndex].trimStart
//            let trimEnd = VideoViewModel.trimValues[currentIndex].trimEnd
//
//            let newTrimStart = max(trimStart + dragValue / totalWidth, 0)
//            let newTrimEnd = min(trimEnd + dragValue / totalWidth, 1)
//
//            VideoViewModel.trimValues[currentIndex].trimStart = newTrimStart
//            VideoViewModel.trimValues[currentIndex].trimEnd = newTrimEnd
//        }
//    }
//
//    func endVideoTrim(at index: Int, dragValue: CGFloat) {
//        if currentIndex == index {
//            // Ensure the trim values are within the valid range (0 to 1)
//            VideoViewModel.trimValues[currentIndex].trimStart = max(VideoViewModel.trimValues[currentIndex].trimStart, 0)
//            VideoViewModel.trimValues[currentIndex].trimEnd = min(VideoViewModel.trimValues[currentIndex].trimEnd, 1)
//        }
//    }
//
//    func trimVideo(at index: Int) {
//        // Perform the video trimming here based on the trim values
//        let start = CGFloat(VideoViewModel.trimValues[index].trimStart)
//        let end = CGFloat(VideoViewModel.trimValues[index].trimEnd)
//
//        // Get the URL of the video to be trimmed
//        guard index < videos.count else {
//            print("Invalid index")
//            return
//        }
//        let videoURL = URL(string: videos[index].uri)!
//
//        // Create an AVAsset for the video
//        let asset = AVAsset(url: videoURL)
//
//        // Load the duration of the asset using AVAssetTrack
//        let assetKeys = ["duration"]
//        asset.loadValuesAsynchronously(forKeys: assetKeys) { [weak self] in
//            var error: NSError? = nil
//            let status = asset.statusOfValue(forKey: "duration", error: &error)
//            switch status {
//            case .loaded:
//                guard let assetTrack = asset.tracks(withMediaType: .video).first else {
//                    print("Failed to load video track.")
//                    return
//                }
//
//                let duration = assetTrack.timeRange.duration.seconds
//                let startTime = CMTime(seconds: Double(duration) * Double(start), preferredTimescale: asset.duration.timescale)
//                let endTime = CMTime(seconds: Double(duration) * Double(end), preferredTimescale: asset.duration.timescale)
//                let timeRange = CMTimeRange(start: startTime, end: endTime)
//
//                // Create an AVAssetExportSession
//                guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
//                    print("Error creating AVAssetExportSession")
//                    return
//                }
//
//                // Set the output file type (e.g., mov, mp4, etc.)
//                let outputFileType = AVFileType.mp4
//                let outputFileName = "trimmed_video.mp4"
//                let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(outputFileName)
//
//                // Configure the export session
//                exportSession.outputFileType = outputFileType
//                exportSession.outputURL = outputURL
//                exportSession.timeRange = timeRange
//
//                // Perform the export
//                exportSession.exportAsynchronously {
//                    if exportSession.status == .completed {
//                        // The trimming process completed successfully
//                        // You can do something with the trimmed video file at outputURL
//                        print("Video trimming completed")
//                        // Update the videos array with the trimmed video's URL
//                        DispatchQueue.main.async {
//                            self?.videos[index].uri = outputURL.absoluteString
//                        }
//                    } else {
//                        // The trimming process failed or was cancelled
//                        print("Video trimming failed")
//                    }
//                }
//            case .failed, .cancelled, .loading, .unknown:
//                print("Failed to load asset duration.")
//            }
//        }
//    }
//
//}

//
//  PreviewVideoPlayerView.swift
//  homie-ios
//
//  Created by Diego Lares on 8/25/23.
//

import SwiftUI
import AVKit
import Combine

struct PreviewVideoPlayerView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    let video: Video
    
    @Binding var isPlaying: Bool {
        willSet(newValue) {
            print("Video \(String(describing: video.caption)) isPlaying state will change to \(newValue)")
        }
    }
    @State private var showClosedCaptionOptions: Bool = false
    @State var currentLoopControl: String = "loop"

    @State private var showTranscription: Bool = false
    @State private var showClosedCaptions: Bool = false

    @Binding var isMuted: Bool {
        didSet {
            print("isMuted set to:", isMuted)
        }
    }
    @State var videoDuration: Double = 0 {
        didSet {
            print("videoDuration:", videoDuration)
        }
    }
    @State var currentPlayerTime: Double = 0 {
        willSet {
            //print("currentPlayerTime set to:", currentPlayerTime)
        }
    }
    @State var trianglePosition: CGFloat = 0 {
        didSet {
            print("trianglePosition:", trianglePosition)
        }
    }
    @State var isDragging: Bool = false {
        didSet {
            print("isDragging:", isDragging)
        }
    }
    @State private var playbackProgressSubscription: AnyCancellable?

    init(video: Video, isPlaying: Binding<Bool>, isMuted: Binding<Bool>) {
        self.video = video
        _isPlaying = isPlaying
        _isMuted = isMuted
    }
    
    var body: some View {
        PreviewVideoPlayer(url: video.videoUrl, isPlaying: $isPlaying, isMuted: $isMuted, currentPlayerTime: $currentPlayerTime, trianglePosition: $trianglePosition, videoDuration: $videoDuration, isDragging: $isDragging, currentLoopControl: $currentLoopControl)
        .frame(width: UIScreen.main.bounds.width * 0.33, height: UIScreen.main.bounds.height * 0.23)
        
    }
    
    struct PreviewVideoPlayer: UIViewControllerRepresentable {
        var url: URL?
        @Binding var isPlaying: Bool {
            didSet {
                print("isPlaying in customvideoPlayer:", isPlaying)
            }
        }
        @Binding var isMuted: Bool {
            didSet {
                print("isMuted:", isMuted)
            }
        }
        @Binding var currentPlayerTime: Double {
            didSet {
                //print("currentPlayerTime in customVideoPlayer:", currentPlayerTime)
            }
        }

        @Binding var trianglePosition: CGFloat {
            didSet {
                //print("trianglePosition in customVideoPlayer:", trianglePosition)
            }
        }
        @Binding var videoDuration: Double


        @Binding var isDragging: Bool {
            didSet {
                print("isDragging:", isDragging)
            }
        }
        
        @Binding var currentLoopControl: String
        var currentPlayerTimeUpdateQueue = DispatchQueue(label: "currentPlayerTimeUpdateQueue")
        @State private var playbackProgressSubscription: AnyCancellable?

        func makeUIViewController(context: Context) -> AVPlayerViewController {
            let playerViewController = AVPlayerViewController()
            
            if let url = url {
                let player = AVPlayer(url: url)
                player.isMuted = isMuted
                
                player.currentItem?.audioTimePitchAlgorithm = .timeDomain
                player.play()
                
                let asset = AVAsset(url: url)
                Task { @MainActor in
                    let duration = try await asset.load(.duration).seconds
                    self.videoDuration = duration
                }
                playerViewController.player = player
                playerViewController.showsPlaybackControls = false
                playerViewController.videoGravity = .resizeAspectFill
                
                let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
                playerViewController.view.addGestureRecognizer(tapGesture)

               context.coordinator.setupTimeObserver(player: player)
                context.coordinator.setupNotifications(player: player)
                
 
                
                return playerViewController
            } else {
                return playerViewController
            }
        }

        func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
            if let player = uiViewController.player {

                if !isDragging {
                    if isPlaying {
                        //print("playing")
                       // player.pause()

                        //player.seek(to: CMTime(seconds: currentPlayerTime, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)

                        player.currentItem?.audioTimePitchAlgorithm = .timeDomain
                        player.play()

                    } else {
                        player.pause()
                    }
                } else {
                    if isPlaying {
                        //isPlaying = false
                        player.pause()
                        player.seek(to: CMTime(seconds: currentPlayerTime, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
                    } else {
                        player.seek(to: CMTime(seconds: currentPlayerTime, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)

                    }
                    
                }
                if !isPlaying && currentPlayerTime == 0{
                    //print("restarted")
                    currentPlayerTimeUpdateQueue.async {
                        player.seek(to: CMTime(seconds: 0, preferredTimescale: 10))
                        isPlaying = true
                    }
                    
                }

                player.isMuted = isMuted

                // Update the timeObserver whenever currentPlayerTime changes
                //context.coordinator.setupTimeObserver(player: player, currentPlayerTime: $currentPlayerTime)
                
                // Check if there's a significant discrepancy between currentPlayerTime and the time reported by the time observer
                let timeDiscrepancyThreshold = 0.1 // Adjust the threshold as needed

                currentPlayerTimeUpdateQueue.async {
                    if abs(currentPlayerTime - player.currentTime().seconds) > timeDiscrepancyThreshold {
                        DispatchQueue.main.async {
                            // Update currentPlayerTime on the main thread
                            if isPlaying {
                                //isPlaying = false
                                player.pause()
                                player.seek(to: CMTime(seconds: currentPlayerTime, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
                                player.play()
//                                isPlaying = true
                            } else {
                                player.seek(to: CMTime(seconds: currentPlayerTime, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)

                            }

                            //currentPlayerTime = player.currentTime().seconds
                        }
                    }
                }
            }
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }
    
        class Coordinator: NSObject {
            let parent: PreviewVideoPlayer
            var playerReference: AVPlayer?
            var timeObserverReference: Any?
            
            init(parent: PreviewVideoPlayer) {
                self.parent = parent
                super.init()
                
                // Create a single time observer when the coordinator is initialized
//                if let player = playerReference {
//                    setupTimeObserver(player: player)
//                }
            }

            func setupTimeObserver(player: AVPlayer) {
                let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                timeObserverReference = player.addPeriodicTimeObserver(forInterval: interval, queue: nil) { [weak self] time in
                    guard let self = self else { return }

                    DispatchQueue.main.async {
                        self.parent.currentPlayerTime = time.seconds
                        self.parent.trianglePosition = CGFloat(time.seconds / self.parent.videoDuration) * (UIScreen.main.bounds.width / 1.2)
                        
                    }
                }
            }
            
            func setupNotifications(player: AVPlayer) {
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { _ in
                    if self.parent.currentLoopControl == "loop" {
                        DispatchQueue.main.async {
                            self.parent.isPlaying = false
                            //player.seek(to: CMTime(seconds: 0, preferredTimescale: 10))
                            self.parent.currentPlayerTime = 0
                            self.parent.isPlaying = true
                            
                        }
                    } else {
                        //player.pause()
                        self.parent.isPlaying = false
                    }
                }
            }
            
            @objc func handleTap(_ gesture: UITapGestureRecognizer) {
                parent.isPlaying.toggle()
            }
            
            deinit {
                if let player = playerReference, let timeObserver = timeObserverReference {
                    player.removeTimeObserver(timeObserver)
                }
                self.parent.playbackProgressSubscription?.cancel()

            }
        }
    }
}

//struct PreviewVideoPlayerView_Previews: PreviewProvider {
//    static var previews: some View {
//        PreviewVideoPlayerView()
//    }
//}

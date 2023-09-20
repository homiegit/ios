import SwiftUI
import Photos
import AVKit
import Combine

struct VideoPlayerView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var viewRouter: ViewRouter

    @State var video: Video {
        didSet {
            print("video::", video)
        }
    }
    @State var user: IUser
    
    @State var showInfo: Bool = false
    @State var showSources: Bool = false

    @State private var showComments: Bool = false
    @State private var showCommentSources: Bool = false
    @State private var showCommentInfo: Bool = false

    @State private var commentsSet: Bool = false
    @State private var commentsArray: [IComment]? {
        didSet {
            print("videoCommentsArray set to:", commentsArray as Any)
        }
    }
    @State private var userCommentsMapping: [String: IUser] = [:] {
        didSet {
            print("videoUserCommentsMapping set to:", userCommentsMapping)
        }
    }

    @State private var comment: String = ""

    @Binding var isPlaying: Bool {
        didSet(newValue) {
            print("Video \(String(describing: video.caption)) isPlaying state will change to \(newValue)")
        }
    }
    @State var showClosedCaptionOptions: Bool = false
    @State var showLoopControls: Bool = false
    @Binding var currentLoopControl: String

    @State var showTranscription: Bool = false
    @State var showClosedCaptions: Bool = false
    @State var showPlaybackSpeedBar: Bool = false

    @Binding var isMuted: Bool {
        didSet {
            print("isMuted set to:", isMuted)
        }
    }
    @Binding var showHeader : Bool
    @Binding var currentIndex: Int
    @State var accumulatedSecondsWatched: Double = 0 {
        didSet {
            print("accumulatedSecondsWatched set to:", accumulatedSecondsWatched)
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
    @State var currentFormattedTime: String = "00:00"
    @State var formattedVideoDuration: String = ""
    @State var trianglePosition: CGFloat = 0 {
        didSet {
            print("trianglePosition:", trianglePosition)
        }
    }
    @State var circlePosition: Float = 100
    @State var playbackSpeedBar: Float = 150
    @State var playbackSpeed: Float = 1

    @State var isDragging: Bool = false {
        didSet {
            print("isDragging:", isDragging)
        }
    }
    @State var showNextIndex: Bool = false
    @State var searchTranscriptionTerm: String = ""
    @State private var playbackProgressSubscription: AnyCancellable?
    @State private var previousPath: String? = nil

    @State var alreadyLiked: Bool = false
    @State var alreadyDisliked: Bool = false
    
    @State var showUserSources: Bool = false
    @State var showActions: Bool = false
    
    @Binding var videoSize: Double
    @Binding var videoPositionY: CGFloat
    
    @State var showDownloadSuccess: Bool = false
    @State var showDownloadFailure: Bool = false
    
    @State var showReport: Bool = false
    @State var reportReasons: [String] = ["false teaching", ""]
    
    @State var reportText: String = ""


    init(video: Video, user: IUser, isPlaying: Binding<Bool>, currentLoopControl: Binding<String>, isMuted: Binding<Bool>, showHeader: Binding<Bool>, currentIndex: Binding<Int>, videoSize: Binding<Double>, videoPositionY: Binding<CGFloat>) {
        _video = State(initialValue: video)
        _user = State(initialValue: user)
        _isPlaying = isPlaying
        _currentLoopControl = currentLoopControl
        _isMuted = isMuted
        _showHeader = showHeader
        _currentIndex = currentIndex
        _videoSize = videoSize
        _videoPositionY = videoPositionY
    }

    var body: some View {
        VStack {
            HStack {
                VStack {
                    if showHeader {
                        UserHeaderView(video: video, showInfo: $showInfo, borderColor: borderColor, showUserSources: $showUserSources, showActions: $showActions, user: user)
                            .padding(.bottom, -3)
                    
                    }
                    Text(video.caption ?? "")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                }
                .padding(.top, 5)
                .padding(.bottom, -7)
            
            }

           videoContent()
                .overlay(
                    HStack(alignment: .top) {
                        if showInfo {
                            Spacer()
                            VStack {
                                Text("Sources")
                                    .font(.system(size: 20).bold())
                                    .foregroundColor(.black)
                                if let sources = video.isVideoReliable.proof?.sources {
                                    ForEach(sources, id: \.self) { source in
                                        Button(action: {
                                            DispatchQueue.main.async {
                                                viewRouter.popToView("BibleView", atIndex: viewRouter.path.count)
                                                viewModel.bibleSource = BibleSource(book: source.book, chapter: source.chapter)
                                             
                                            }
                                            //fetchAndOpenURL(url: source.url)
                                        }) {
                                            Text("\(source.book) \(source.chapter)")
                                                .font(.system(size: 15))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            .frame(width: UIScreen.main.bounds.width / 2, height: 70)
                            .background(borderColor)
                            .padding(.top, -(UIScreen.main.bounds.height / 4))
                        }
                            
                    }
                        
                )

            VStack {
                HStack {
                    Spacer()
                    Rectangle()
                        .frame(width: UIScreen.main.bounds.width / 1.2, height: 5)
                        .foregroundColor(Color.blue)
                        .overlay(
                            Image(systemName: "arrowtriangle.down")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .position(x: trianglePosition, y: -10)
                                .gesture(DragGesture()
                                    .onChanged { gesture in
                                        let newPosition = max(0, min(gesture.location.x, UIScreen.main.bounds.width / 1.2))
                                        print("new triangle Position:", newPosition)
                                        trianglePosition = newPosition
                                        currentPlayerTime = Double((newPosition / (UIScreen.main.bounds.width / 1.2)) * videoDuration)
                                        isDragging = true
                                    }
                                    .onEnded { _ in
                                        isDragging = false
                                    }
                                )
                        )
                    Spacer()
                }
            
                    
                HStack {
                    Spacer()
                    Button(action: {
                        isPlaying = false
                        currentPlayerTime = 0
                        
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    Button(action: {
                        isMuted.toggle()
                        
                    }) {
                        Image(systemName: isMuted ? "volume.slash" : "volume.3")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    Button(action: {
                        showLoopControls.toggle()
                        if showClosedCaptionOptions {
                            showClosedCaptionOptions.toggle()
                        }
                        if showPlaybackSpeedBar {
                            showPlaybackSpeedBar.toggle()
                        }
                        if showComments {
                            showComments.toggle()
                        }
                        if showTranscription {
                            showTranscription.toggle()
                        }
                        
                    }) {
                        Image(systemName: currentLoopControl == "swipeOnEnd" ? "arrow.up.to.line.alt" : (currentLoopControl == "pauseOnEnd" ? "pause" : "arrow.2.circlepath")
                        )
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    Button(action: {
                        showPlaybackSpeedBar.toggle()
                        if showLoopControls {
                            showLoopControls.toggle()
                        }
                        if showClosedCaptionOptions {
                            showClosedCaptionOptions.toggle()
                        }
                        if showComments {
                            showComments.toggle()
                        }
                        if showTranscription {
                            showTranscription.toggle()
                        }
                        
                    }) {
                        Image(systemName: showPlaybackSpeedBar ? "stopwatch.fill" : "stopwatch")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    Button(action: {
                        showClosedCaptionOptions.toggle()
                  
                        if showLoopControls {
                            showLoopControls.toggle()
                        }
                        if showPlaybackSpeedBar {
                            showPlaybackSpeedBar.toggle()
                        }
                        if showTranscription {
                            showTranscription.toggle()
                        }
                        if showComments {
                            showComments.toggle()
                        }
                        
                    }) {
                        Image(systemName: "captions.bubble")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    Button(action: {
                        showComments.toggle()
                        
                        //fetchCommentsIfNeeded(video: video)
                        if showLoopControls {
                            showLoopControls.toggle()
                        }
                        if showClosedCaptionOptions {
                            showClosedCaptionOptions.toggle()
                        }
                        if showPlaybackSpeedBar {
                            showPlaybackSpeedBar.toggle()
                        }
                        if showTranscription {
                            showTranscription.toggle()
                        }
                        if showReport {
                            showReport.toggle()
                        }
                        if showInfo {
                            showInfo.toggle()
                        }
                        
                    }) {
                        Image(systemName: showComments ? "bubble.right.fill" : "bubble.right")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }

            }
            .background(Color.clear)
        }
        
        .onAppear {
            // Store the current viewRouter.path when the view appears
            previousPath = viewRouter.path.last
            if let userId = UserDefaults.userProfile?._id {
                if let likes = video.likes {
                    let alreadyliked = likes.contains { like in
                        return like._ref == userId
                    }

                    if alreadyliked {
                        print("User already liked")
                        alreadyLiked = true
                    } else {
                        print("User hasn't liked")
                    }
                }
                if let dislikes = video.dislikes {
                    let alreadydisliked = dislikes.contains { dislike in
                        return dislike._ref == userId
                    }
                    if alreadydisliked {
                        print("User already disliked")
                        alreadyDisliked = true
                    } else {
                        print("User hasn't disliked")
                    }
                }
            }
        }
        .onDisappear {
            isPlaying = false

            //var videoId: String?
//            if let previousPath = previousPath {
//
//                if previousPath.contains("SingleVideoView") {
//                    videoId = viewModel.singleVideo?._id
//                } else if let currentIndex = viewModel.currentIndex {
//                    print("viewmodel currentIndex:", currentIndex)
//                    videoId = viewModel.videos[currentIndex]._id
//                }
//
//                if let videoId = videoId {
//                    print("updating", viewModel.currentIndex ?? "nil", ":", videoId)
//
//                    let timeNow = Date()
//                    print("timeNow:", timeNow)
//                    updateViewAndSecondsWatched(
//                        videoId: videoId,
//                        secondsWatched: accumulatedSecondsWatched,
//                        timeViewed: timeNow
//                    ) { result in
//                        switch result {
//                        case .success:
//                            print("successfully updated views")
//                            DispatchQueue.main.async {
//                                accumulatedSecondsWatched = 0
//                            }
////                            DispatchQueue.main.async {
////                                if let currentIndex = viewModel.currentIndex,
////                                   currentIndex < viewModel.videos.count {
////                                    viewModel.currentIndex = currentIndex + 1
////                                } else if let currentIndex = viewModel.currentIndex,
////                                          currentIndex == viewModel.videos.count {
////                                    print("last index")
////                                }
////                            }
//                        case .failure(let error):
//                            print("error updatingviewandsecondswatched", error)
//                        }
//                    }
//                }
//            }
        }
        .background(RoundedRectangle(cornerRadius: 18).stroke(borderColor, lineWidth: 3))
        .buttonStyle(NoHighlightButtonStyle())
        .scaleEffect(CGFloat(videoSize))
        .padding(.trailing, 15)
        //
        .position(CGPoint(x: Double(0), y: Double(0)))
        .position(x: UIScreen.main.bounds.width , y: videoPositionY)
        .onChange(of: video.videoUrl){ newVideo in
            print("newVideo:", newVideo as Any)
        }
    }
    
    func likeVideo(completion: @escaping ((Result<String, Error>) -> Void)) {
        if let userId = UserDefaults.userProfile?._id, let videoId = video._id {
            guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
                  let likeVideoEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/likeVideo/\(videoId)/\(userId)") else {
                print("Error: Invalid server URL or endpoint")
                return
            }
            print("likeVideoEndpoint:", likeVideoEndpoint)
            
            var request = URLRequest(url: likeVideoEndpoint)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type") // Specify content type

            // Use JSONEncoder to convert the comment object to JSON data
            let encoder = JSONEncoder()
            do {
                let videoData = try encoder.encode(video)
                request.httpBody = videoData
            } catch {
                print("Error: Failed to encode video object to JSON")
                completion(.failure(error))
                return
            }
            
            // Set the userID as a parameter in the request URL or in the headers if needed
            request.addValue(userId, forHTTPHeaderField: "User-ID")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Handle the response
                if let httpResponse = response as? HTTPURLResponse {
                    if (200..<300).contains(httpResponse.statusCode) {
                        completion(.success("Video liked successfully"))
                    } else {
                        completion(.failure(NSError(domain: "Server", code: httpResponse.statusCode, userInfo: nil)))
                    }
                }
            }
            
            task.resume()
        }
    }
    
    func dislikeVideo(completion: @escaping ((Result<String, Error>) -> Void)) {
        if let userId = UserDefaults.userProfile?._id, let videoId = video._id {
            guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
                  let dislikeVideoEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/dislikeVideo/\(videoId)/\(userId)") else {
                print("Error: Invalid server URL or endpoint")
                return
            }
            print("dislikeVideoEndpoint:", dislikeVideoEndpoint)
            
            var request = URLRequest(url: dislikeVideoEndpoint)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type") // Specify content type

            // Use JSONEncoder to convert the comment object to JSON data
            let encoder = JSONEncoder()
            do {
                let videoData = try encoder.encode(video)
                request.httpBody = videoData
            } catch {
                print("Error: Failed to encode video object to JSON")
                completion(.failure(error))
                return
            }
            
            // Set the userID as a parameter in the request URL or in the headers if needed
            request.addValue(userId, forHTTPHeaderField: "User-ID")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Handle the response
                if let httpResponse = response as? HTTPURLResponse {
                    if (200..<300).contains(httpResponse.statusCode) {
                        completion(.success("Video disliked successfully"))
                    } else {
                        completion(.failure(NSError(domain: "Server", code: httpResponse.statusCode, userInfo: nil)))
                    }
                }
            }
            
            task.resume()
        }
    }
    
    func fetchAndOpenURL(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("Error: Unable to open URL")
        }
    }

    
    func goToLink(urlString: String) {
        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("Error: Unable to open URL")
            }
        } else {
            print("Error: Invalid URL")
        }
    }
    
    @ViewBuilder
    private func videoContent() -> some View {
        CustomVideoPlayer(
            url: video.videoUrl,
            isPlaying: $isPlaying,
            isMuted: $isMuted,
            currentPlayerTime: $currentPlayerTime,
            accumulatedSecondsWatched: $accumulatedSecondsWatched,
            trianglePosition: $trianglePosition,
            videoDuration: $videoDuration,
            playbackSpeed: $playbackSpeed,
            isDragging: $isDragging,
            currentLoopControl: $currentLoopControl,
            showNextIndex: $showNextIndex
        )
        .frame(width: UIScreen.main.bounds.width / 1.05)
        
        .onChange(of: showNextIndex) { _ in
            print("showNextIndex changed to:", showNextIndex)
            if showNextIndex {
                DispatchQueue.main.async {
                    viewModel.currentIndex += 1
                    showNextIndex = false
                
                }
            }
        }
        .overlay(
            VStack {
                if showReport{
                    Spacer()
                }
                HStack {
                    if showActions {
                        VStack(spacing: 5) {
                            Button(action:{
                                if let videoUrl = video.videoUrl {
                                    downloadVideo(videoURL: videoUrl)
                                    showActions.toggle()
                                }
                            }) {
                                Text("Download Video")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                            }
                            Button(action:{
                                showReport.toggle()
                                showActions.toggle()
                            }) {
                                Text("Report")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(5)
                        .background(Color.black)
                        .border(Color.white, width: 2)
                    }
                    if showDownloadSuccess {
                        Text("Saved to Photos")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Color.black)
                            .border(Color.white, width: 2)
                            .onAppear{
                                Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) {timer in
                                    showDownloadSuccess = false
                                    timer.invalidate()
                                }
                            }
                    }
                    if showDownloadFailure {
                        Text("Error Saving to Photos")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Color.black)
                            .border(Color.white, width: 2)
                            .onAppear{
                                Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) {timer in
                                    showDownloadFailure = false
                                    timer.invalidate()
                                }
                            }
                    }
                    Spacer()
                    
                    if showReport {
                        VStack{
                            
                            TextEditor(text: $reportText)
                                .font(.system(size: 15))
                                .foregroundColor(.black)
                                .padding(5)
                                .lineLimit(nil) // Allow unlimited lines
                                .multilineTextAlignment(.leading)
                                .border(Color.clear, width: 2)
                                .highPriorityGesture(DragGesture())
                            Spacer()

                            HStack{
                                Button(action: {
                                    reportText = ""
                                    showReport = false
                                }) {
                                    Text("Cancel")
                                        .foregroundColor(.black)
                                        .padding(5)
                                        .background(Color.white)
                                        .border(Color.gray, width: 2)
                                    
                                }
                                .padding(5)
                                Button(action: {
                                    if !reportText.isEmpty {
                                        report()
                                    }
                                }) {
                                    Text("Report")
                                        .foregroundColor(.black)
                                        .padding(5)
                                        .background(Color.red)
                                        .border(Color.gray, width: 2)
                                    
                                }
                                .padding(5)
                            }
                        }
                        .frame(width: screenWidth / 1.5, height: screenHeight / 3)
                        .background(Color.white)
                        .border(Color.white, width: 2)
                    }
                    
                    if showUserSources {
                        VStack(spacing: 10) {
                            Text("\(user.userName)'s references")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(.bottom, -5)
                            ScrollView(.vertical) {
                                VStack{
                                    if let bibleSources = video.bibleSources {
                                        ForEach(bibleSources, id: \.self) { source in
                                            Button(action: {
                                                DispatchQueue.main.async{
                                                    viewModel.bibleSource = BibleSource(book: source.book, chapter: source.chapter)
                                                    viewRouter.popToView("BibleView", atIndex: viewRouter.path.count)
                                                }
                                            }) {
                                                Text("\(source.book) \(source.chapter)")
                                                    .foregroundColor(Color.purple)
                                            }
                                            .padding(.bottom, 2)
                                        }
                                    }
                                    if let urlSources = video.urlSources {
                                        ForEach(urlSources, id: \.self) { source in
                                            Button(action: {
                                                goToLink(urlString: source.url)
                                            }) {
                                                Text(source.title)
                                                    .foregroundColor(Color.blue)
                                            }
                                            .padding(.bottom, 2)
                                        }
                                    }
                                }
                            }
                            .highPriorityGesture(DragGesture())
                        }
                        .padding(5)
                        .border(Color.white, width: 2)
                        .background(Color.black)
                        .frame(width: UIScreen.main.bounds.width / 1.2, height: UIScreen.main.bounds.height / 6)
                    }
                    Spacer()
                    
                    if showInfo {
                        Spacer()
                        VStack {
                            ScrollView(.vertical) {
                                Text(video.isVideoReliable.proof?.text ?? "")
                                    .foregroundColor(.black)
                            }
                            .highPriorityGesture(DragGesture())
                        }
                        .background(borderColor)
                        .frame(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.height / 8)

                    }
                }
                Spacer()
            }

        )
        .overlay(
            VStack {
                Spacer()
                HStack(alignment: .center) {
                    if video.cues != nil && showClosedCaptions {
                        CueOverlayView(cues: video.cues, playerTime: currentPlayerTime)
                    }
                }
                Spacer()
            }
        )
//        .overlay(
//            ZStack {
//                if showComments {
//                    Spacer()
//                    CommentsView(video: video)
//                        .environmentObject(viewRouter)
//
//                }
//            }
//        )
        .overlay(
            VStack {
                Spacer()
                if showLoopControls {
                    HStack {
                        Spacer(minLength: UIScreen.main.bounds.width / 4.7)
                        VStack {
                            switch currentLoopControl {
                            case "swipeOnEnd":
                                Button(action: {
                                    currentLoopControl = "loop"
                                    showLoopControls.toggle()
                                }) {
                                    Text("Loop")
                                        .font(.system(size: 15))
                                        .padding(5)
                                        .foregroundColor(.white)
                                        .frame(width: 50)
                                        .background(Color.black)
                                        .border(Color.white, width: 1)
                                }
                                Button(action: {
                                    currentLoopControl = "pauseOnEnd"
                                    showLoopControls.toggle()

                                }) {
                                    Text("Pause on end")
                                        .font(.system(size: 15))
                                        .padding(5)
                                        .foregroundColor(.white)
                                        .frame(width: 110)
                                        .background(Color.black)
                                        .border(Color.white, width: 1)
                                }
                            case "pauseOnEnd":
                                Button(action: {
                                    currentLoopControl = "loop"
                                    showLoopControls.toggle()
                                }) {
                                    Text("Loop")
                                        .font(.system(size: 15))
                                        .padding(5)
                                        .foregroundColor(.white)
                                        .frame(width: 50)
                                        .background(Color.black)
                                        .border(Color.white, width: 1)
                                }
                                Button(action: {
                                    currentLoopControl = "swipeOnEnd"
                                    showLoopControls.toggle()

                                }) {
                                    Text("Swipe on end")
                                        .font(.system(size: 15))
                                        .padding(5)
                                        .foregroundColor(.white)
                                        .frame(width: 110)
                                        .background(Color.black)
                                        .border(Color.white, width: 1)
                                }
                            default:
                                Button(action: {
                                    currentLoopControl = "swipeOnEnd"
                                    showLoopControls.toggle()

                                }) {
                                    Text("Swipe on end")
                                        .font(.system(size: 15))
                                        .padding(5)
                                        .foregroundColor(.white)
                                        .frame(width: 110)
                                        .background(Color.black)
                                        .border(Color.white, width: 1)
                                }
                                Button(action: {
                                    currentLoopControl = "pauseOnEnd"
                                    showLoopControls.toggle()

                                }) {
                                    Text("Pause on end")
                                        .font(.system(size: 15))
                                        .padding(5)
                                        .foregroundColor(.white)
                                        .frame(width: 110)
                                        .background(Color.black)
                                        .border(Color.white, width: 1)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                        Spacer()
                    }
                }
            }
        )
        .overlay(
            VStack {
                if showPlaybackSpeedBar {
                    Spacer()
                    HStack {
                        Spacer(minLength: UIScreen.main.bounds.width / 3)
                        Rectangle()
                            .frame(width: 10, height: CGFloat(playbackSpeedBar))
                            .foregroundColor(.blue)
                            .overlay(
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .position(x: 0, y: CGFloat(circlePosition)) // Invert circle position

                                    .overlay(
                                        Text(String(format: "%.1f", playbackSpeed))
                                            .position(x: 10, y: CGFloat( circlePosition) - 60)
                                            .font(.system(size: 20))
                                            .foregroundColor(.black)
                                            .frame(width: 30, height: 30, alignment: .center)
                                    )
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        if isPlaying {
                                            isPlaying = false
                                                //isDragging = true

                                            let newPosition = max(0, min(gesture.location.y, CGFloat(playbackSpeedBar)))
                                            print("newCirclePosition:", newPosition)
                                            circlePosition = Float(newPosition)
                                            let playbackSpeedRange = Float(3.0 - 0.5)
                                            playbackSpeed = 3.0 - playbackSpeedRange * (circlePosition / playbackSpeedBar) // Invert playbackSpeed calculation
                                            isPlaying = true

                                        } else {
                                            //isDragging = true
                                            let newPosition = max(0, min(gesture.location.y, CGFloat(playbackSpeedBar)))
                                            print("newCirclePosition:", newPosition)
                                            circlePosition = Float(newPosition)
                                            let playbackSpeedRange = Float(3.0 - 0.5)
                                            playbackSpeed = 3.0 - playbackSpeedRange * (circlePosition / playbackSpeedBar) // Invert playbackSpeed calculation
                                        }
                                    }
                                    .onEnded { _ in
                                        //isDragging = false
                                    }
                            )
                        Spacer()
                    }

                }
            }
        )
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack {
                        if showClosedCaptionOptions {
                            Button(action: {
                                if showClosedCaptions {
                                    showClosedCaptions.toggle()
                                }
                                if showActions {
                                    showActions.toggle()
                                }
                                if showUserSources {
                                    showUserSources.toggle()
                                }
                                if showInfo {
                                    showInfo.toggle()
                                }
                                
                                showClosedCaptionOptions = false
                                showTranscription.toggle()
                            }) {
                                Text("Transcription")
                                    .font(.system(size: 15))
                                    .padding(5)
                                    .foregroundColor(.white)
                                    .frame(width: 100)
                                    .background(Color.black)
                                    .border(Color.white, width: 1)
                            }
                            Button(action: {
                                if showTranscription {
                                    showTranscription.toggle()
                                }
                                showClosedCaptionOptions = false
                                showClosedCaptions.toggle()
                            }) {
                                Text("Closed-Captions")
                                    .font(.system(size: 15))
                                    .padding(5)
                                    .foregroundColor(.white)
                                    .frame(width: 130)

                                    .background(Color.black)
                                    .border(Color.white, width: 1)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                    Spacer()
                }
            }
        )
        .overlay(
            VStack {
                Spacer()
                if showTranscription {
                    VStack {
                        TextField("Search Transcription", text: $searchTranscriptionTerm)
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                            .border(Color.white, width: 1)
                            .frame(width: UIScreen.main.bounds.width / 2, height: 30, alignment: .center)
                        
                        if let cues = video.cues {
                            ScrollView(.vertical) {
                                VStack(alignment: .leading, spacing: 10) {
                                    
                                    ForEach(cues, id: \.self) { cue in
                                        if let startTime = cue.start_time,
                                           let endTime = cue.end_time,
                                           let alternatives = cue.alternatives {
                                            
                                            ForEach(alternatives, id: \.self) { alternative in
                                                let matchingWord = alternative.content.contains(searchTranscriptionTerm.lowercased())
                                                
                                                HStack {
                                                    Button(action: {
                                                        currentPlayerTime = startTime
                                                    }) {
                                                        Text(alternative.content)
                                                            .font(.system(size: 15))
                                                            .foregroundColor((startTime >= currentPlayerTime && endTime <= currentPlayerTime) ? .blue : .white)
                                                            .multilineTextAlignment(.leading)
                                                            .border(matchingWord ? Color.yellow : Color.clear, width: 2)
                                                            .id(alternative._key)
                                                    }
                                                    Spacer()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(width: UIScreen.main.bounds.width / 1.2, height: UIScreen.main.bounds.height / 4.5)
                            .highPriorityGesture(DragGesture())
                        } else {
                            Text("no cues")
                                .foregroundColor(.white)
                        }
                    }
//                    .frame(width: UIScreen.main.bounds.width / 1.2, height: UIScreen.main.bounds.height / 4)
                    .background(Color.black.opacity(0.7))
                }
            }
        )
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 20) {
                        HStack {
                            Text("\(video.likes?.count ?? 0)")
                                .font(.system(size: 22).bold())
                                .foregroundColor(.white)
                            Button(action: {
                                if !alreadyLiked{
                                    likeVideo { result in
                                        switch result {
                                        case .success:
                                            alreadyLiked = true
                                            alreadyDisliked = false
                                        case .failure(let error):
                                            print("Error liking video:", error)
                                        }
                                    }
                                } else if alreadyLiked {
                                    likeVideo { result in
                                        switch result {
                                        case .success:
                                            alreadyLiked = false
                                            alreadyDisliked = false
                                        case .failure(let error):
                                            print("Error un-liking video:", error)
                                        }
                                    }
                                }
                            }) {
                                Image(systemName: alreadyLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .foregroundColor(alreadyLiked ? Color.blue : Color.white)
                                    .font(.system(size: 27))
                            }
                        }
                        HStack {
                            Text("\(video.dislikes?.count ?? 0)")
                                .font(.system(size: 22).bold())
                                .foregroundColor(.white)
                            
                            Button(action: {
                                if !alreadyDisliked{
                                    dislikeVideo { result in
                                        switch result {
                                        case .success:
                                            alreadyLiked = false
                                            alreadyDisliked = true
                                        case .failure(let error):
                                            print("Error disliking video:", error)
                                        }
                                    }
                                } else if alreadyDisliked {
                                    dislikeVideo { result in
                                        switch result {
                                        case .success:
                                            alreadyLiked = false
                                            alreadyDisliked = false
                                        case .failure(let error):
                                            print("Error un-Disliking video:", error)
                                        }
                                    }
                                }
                            }) {
                                Image(systemName: alreadyDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                    .foregroundColor(alreadyDisliked ? Color.red : Color.white)
                                    .font(.system(size: 27))
                            }
                        }
                        HStack {
                            Text("\(video.views?.count ?? 0)")
                                .font(.system(size: 22).bold())
                                .foregroundColor(.white)

                            Image(systemName: "play")
                                .font(.system(size: 27))
                                .foregroundColor(.white)
                            
                        }
                    }
                }
                HStack{
                    Spacer()
                    if !formattedVideoDuration.isEmpty {
                        Text("\(currentFormattedTime) / \(formattedVideoDuration)")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            //.background(RoundedRectangle(cornerRadius: 18, Color.black.opacity(0.7)))
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(20)

                    }
                    Spacer()
                }
            }
        )
        .onChange(of: currentPlayerTime) { newValue in
            currentPlayerTime = newValue
            let formattedTime = formatTime(seconds: newValue)
            currentFormattedTime = formattedTime

            //print("currentPlayerTime changed to:", newValue)
            //print("video.cues?[0].start_time:",video.cues?[0].start_time as Any)
        }
        .onChange(of: videoDuration) { durationInSeconds in
            videoDuration = durationInSeconds
            let formattedTime = formatTime(seconds: durationInSeconds)
            formattedVideoDuration = formattedTime

        }
        if showComments {
            
            VStack {
                Spacer()
                CommentsView(video: video)
                    .environmentObject(viewRouter)
                
                
            }
        }
        
    }
    func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    func downloadVideo(videoURL: URL) {
        // Create a temporary directory URL within your app's sandboxed directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access app's sandboxed directory")
            return
        }
        
        let tempDirectoryURL = documentsDirectory.appendingPathComponent("temp")
        
        // Check if the temporary file exists and delete it if it does
        if FileManager.default.fileExists(atPath: tempDirectoryURL.path) {
            do {
                try FileManager.default.removeItem(at: tempDirectoryURL)
                print("Existing temporary directory deleted")
            } catch {
                print("Error deleting existing temporary directory: \(error.localizedDescription)")
                return
            }
        }
        
        // Create the temporary directory
        do {
            try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating temporary directory: \(error.localizedDescription)")
            return
        }
        
        // Create a destination URL within the temporary directory
        let destinationURL = tempDirectoryURL.appendingPathComponent(videoURL.lastPathComponent)
        print("destinationURL:", destinationURL)
        
        URLSession.shared.downloadTask(with: videoURL) { (tempURL, response, error) in
            if let error = error {
                print("Error downloading video: \(error.localizedDescription)")
                return
            }

            guard let tempURL = tempURL else {
                print("No temporary URL received while downloading video")
                return
            }

            do {
                // Copy the downloaded video to the temporary directory
                try FileManager.default.copyItem(at: tempURL, to: destinationURL)

                // Check if the video can be saved to the photo library
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        // Save the video to the photo library
                        PHPhotoLibrary.shared().performChanges {
                            let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: destinationURL)
                            creationRequest?.placeholderForCreatedAsset
                        } completionHandler: { (success, error) in
                            if success {
                                print("Video saved to the photo library")
                                showDownloadSuccess = true
                                // Delete the temporary file after it's saved to the photo library
                                do {
                                    try FileManager.default.removeItem(at: destinationURL)
                                    print("Temporary file deleted")
                                } catch {
                                    print("Error deleting temporary file: \(error.localizedDescription)")
                                }
                            } else if let error = error {
                                print("Error saving video to the photo library: \(error.localizedDescription)")
                                showDownloadFailure = true
                            }
                        }
                    } else {
                        print("Permission to access the photo library denied")
                    }
                }
            } catch {
                print("Error copying video to temporary directory: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func report() {
        guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
              let createVideoEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/createReport") else {
            print("Error: Invalid server URL or endpoint")
            return
        }
        
        var request = URLRequest(url: createVideoEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let videoId = video._id {
            let report: Report = Report(postedBy: UserDefaults.userProfile?._id ?? "unknown", videoId: videoId, text: reportText)
                        
            do {
                // Encode the Report instance as JSON data
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(report)
                request.httpBody = jsonData
                
                // Create a custom session configuration
                let sessionConfig = URLSessionConfiguration.default
                sessionConfig.timeoutIntervalForRequest = 600 // Set the timeout interval in seconds
                
                // Create a URLSession with the custom configuration
                let session = URLSession(configuration: sessionConfig)
                
                // Use the custom session for data task
                session.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                        //completion(.failure(error))
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if (200...299).contains(httpResponse.statusCode) {
                            print("report created")
                            showReport = false
                            //completion(.success(()))
                            
                        } else {
                            print("Error: HTTP status code \(httpResponse.statusCode)")
                            showReport = false

                            //completion(.failure(NSError(domain: "HTTP status code \(httpResponse.statusCode)", code: 0, userInfo: nil)))
                        }
                    }
                }.resume()
            } catch {
                print("Error encoding report as JSON: \(error)")
                // Handle the error here
            }
        }
    }

    
//    @ViewBuilder
//    private func transcriptionBoxContent() -> some View {
//        if let cues = video.cues {
//            ScrollView(.vertical) {
//                ForEach(cues, id: \.self) { cue in
//                    if let startTime = cue.start_time,
//                       let endTime = cue.end_time,
//                       let alternatives = cue.alternatives {
//
//                        let isWithinTimeRange = startTime >= currentPlayerTime && endTime <= currentPlayerTime
//                        let matchingWord = alternatives.contains { alternative in
//                            alternative.content.contains(searchTranscriptionTerm)
//                        }
//
//                        VStack(alignment: .leading) {
//                            ForEach(alternatives, id: \.self) { alternative in
//                                Text(alternative.content)
//                                    .font(.system(size: 15))
//                                    .foregroundColor(isWithinTimeRange ? .blue : .white)
//                                    .background(matchingWord ? Color.yellow : Color.clear)
//                            }
//                        }
//                        .border(Color.white, width: 1)
//                    }
//                }
//            }
//            .frame(width: UIScreen.main.bounds.width / 1.2, height: UIScreen.main.bounds.height)
//            .border(Color.blue, width: 2)
//
//        }
//    }




    
    // Determine the border color based on reliability
    var borderColor: Color {
        switch video.isVideoReliable.reliability {
        case "false":
            return .red
        case "inaccurate":
            return .yellow
        case "true":
            return .green
        default:
            return .white
        }
    }
    
    // Determine the overlay color based on reliability
    var overlayColor: Color {
        switch video.isVideoReliable.reliability {
        case "false":
            return .red.opacity(0.4)
        case "inaccurate":
            return .yellow.opacity(0.4)
        case "true":
            return .green.opacity(0.4)
        default:
            return .clear
        }
    }
    
    struct CustomVideoPlayer: UIViewControllerRepresentable {
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
        @Binding var accumulatedSecondsWatched: Double {
            didSet {
                //print("accumulatedSecondsWatched in customVideoPlayer:", accumulatedSecondsWatched)
            }
        }
        @Binding var trianglePosition: CGFloat {
            didSet {
                //print("trianglePosition in customVideoPlayer:", trianglePosition)
            }
        }
        @Binding var videoDuration: Double
        @Binding var playbackSpeed: Float {
            didSet {
                print("playbackSpeed in customVideoPlayer set to:", playbackSpeed)
            }
        }

        @Binding var isDragging: Bool {
            didSet {
                print("isDragging:", isDragging)
            }
        }
        
        @Binding var currentLoopControl: String
        @Binding var showNextIndex: Bool
        var currentPlayerTimeUpdateQueue = DispatchQueue(label: "currentPlayerTimeUpdateQueue")
        @State private var playbackProgressSubscription: AnyCancellable?

        func makeUIViewController(context: Context) -> AVPlayerViewController {
            let playerViewController = AVPlayerViewController()
            
            if let url = url {
                let player = AVPlayer(url: url)
                player.isMuted = isMuted
                
                player.currentItem?.audioTimePitchAlgorithm = .timeDomain
                player.playImmediately(atRate: playbackSpeed)

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
                        player.playImmediately(atRate: playbackSpeed)
                        //print("player.rate:", player.rate)

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

                    player.seek(to: CMTime(seconds: 0, preferredTimescale: 10))
                    //isPlaying = true
                    
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
            let parent: CustomVideoPlayer
            var playerReference: AVPlayer?
            var timeObserverReference: Any?
            
            init(parent: CustomVideoPlayer) {
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
                        
                        if self.parent.isPlaying {
                            self.parent.accumulatedSecondsWatched += 0.1

                        }
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
                        
                    } else if self.parent.currentLoopControl == "swipeOnEnd"{
                        
                        //player.pause()
                        self.parent.isPlaying = false
                        self.parent.showNextIndex = true
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

struct CueOverlayView: View {
    let cues: [Items]?
    let playerTime: Double
    
    var body: some View {
        ForEach(cues ?? [], id: \._key) { cue in
            if let startTime = cue.start_time, let endTime = cue.end_time {
                if playerTime >= startTime && playerTime <= endTime {
                    Text(cue.alternatives?[0].content ?? "")
                        .foregroundColor(.white)
                        .background(Color.black)
                        .padding(10)
                }
            }
        }
    }
}

func updateViewAndSecondsWatched(videoId: String, secondsWatched: Double, timeViewed: Date, completion: @escaping (Result<Data, Error>) -> Void) {
    guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
          let updateViewAndSecondsWatchedEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/updateViewAndSecondsWatched") else {
        print("Error: Invalid server URL or endpoint")
        return
    }
    
    print("updateViewAndSecondsWatchedEndpoint:", updateViewAndSecondsWatchedEndpoint)
    
    // Convert the timeViewed date to a string with time zone using a date formatter
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z" // Include Z for time zone
    dateFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
    let timeViewedString = dateFormatter.string(from: timeViewed)
    print("timeViewedString:", timeViewedString)
    
    // Construct the request body
    let requestBody: [String: Any] = [
        "videoId": videoId,
        "secondsWatched": Int(secondsWatched),
        "userRef": UserDefaults.userProfile?._id ?? "",
        "timeViewed": timeViewedString // Use the formatted timeViewedString
    ]
    
    do {
        let requestBodyData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        var request = URLRequest(url: updateViewAndSecondsWatchedEndpoint)
        request.httpMethod = "POST"
        request.httpBody = requestBodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data {
                print("data from updateViewAndSecondsWatched:", data)
                completion(.success(data))
            }
        }
        task.resume()
    } catch {
        completion(.failure(error))
    }
}


struct EditVideoPlayer: UIViewControllerRepresentable {
    var currentIndex: Int = 0 // Current index of the playing video
    var urls: [URL]

    @Binding var isPlaying: Bool
    @State var isMuted: Bool = false
    
    init(currentIndex: Int = 0, urls: [URL] = [], isPlaying: Binding<Bool> = .constant(true), isMuted: Bool = false) {
        self.currentIndex = currentIndex
        self.urls = urls
        self._isPlaying = isPlaying
        self.isMuted = isMuted
    }
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let coordinator = Coordinator(parent: self)
        
        let playerViewController = AVPlayerViewController()
        playerViewController.player = coordinator.player
        playerViewController.showsPlaybackControls = false
        playerViewController.delegate = coordinator
        playerViewController.transitioningDelegate = coordinator
        playerViewController.videoGravity = .resizeAspectFill
        
        // Set up player item observers for looping
        NotificationCenter.default.addObserver(coordinator, selector: #selector(Coordinator.playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        urls.forEach {
            NotificationCenter.default.addObserver(coordinator, selector: #selector(Coordinator.playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: $0)
        }
        
        // Set up tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleTapGesture(_:)))
        playerViewController.view.addGestureRecognizer(tapGesture)
        
        return playerViewController
    }
    
    public func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if isPlaying {
            uiViewController.player?.play()
        } else {
            uiViewController.player?.pause()
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public final class Coordinator: NSObject, AVPlayerViewControllerDelegate, UIViewControllerTransitioningDelegate {
        var urls: [URL]

        public let parent: EditVideoPlayer
        var player: AVQueuePlayer? // Updated to AVQueuePlayer to handle multiple URLs
        
        init(parent: EditVideoPlayer) {
            self.parent = parent
            self.urls = parent.urls
            super.init()
            
            print("URLs before AVPlayer initialization:", urls)

            // Initialize the AVQueuePlayer with AVPlayerItems
            let playerItems = urls.map { url in // Use map to create AVPlayerItems
                print("Creating AVPlayerItem for URL:", url)
                return AVPlayerItem(url: url)
            }
            self.player = AVQueuePlayer(items: playerItems)
            
            print("Number of player items:", playerItems.count)
        }
        
        @objc public func playerItemDidReachEnd(notification: Notification) {
            // Play next video when the current video reaches the end
            guard let player = player else { return }
            guard let currentItem = player.currentItem else { return }
            
            let currentIndex = player.items().firstIndex(of: currentItem) ?? 0

            // Increment the index or reset to the first video when the last video ends
            let nextIndex = (currentIndex + 1) % urls.count
            
            // Seek to the beginning of the next video
            let nextItem = player.items()[nextIndex]
            player.replaceCurrentItem(with: nextItem)
            player.seek(to: CMTime.zero)
            
            if parent.isPlaying {
                player.play()
            }
        }
        
        public func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            // Toggle isPlaying state on tap
            self.parent.isPlaying.toggle()
        }
        
        @objc func handleTapGesture(_ sender: UITapGestureRecognizer) {
            self.parent.isPlaying.toggle()
            print("isplaying toggled", self.parent.isPlaying)
        }
    }
}

struct NoHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

    
//    struct VideoPlayerView_Previews: PreviewProvider {
//        
//        @State static var isPlaying = false
//        @State static var isMuted = false
//        @State static var showHeader = true
//        @State static var currentIndex: Int? = nil
//        
//        static var previews: some View {
//            // Create some dummy data for preview
//            let reliable = Video.IsVideoReliable(reliability: "true", proof: nil)
//            let user = PostedBy(_ref: "123")
//            
//            let video = Video(
//                isVideoReliable: reliable,
//                url: URL(string: "https://cdn.sanity.io/files/ynqkzz99/production/fd920af275b17bc8c3fbc6ec2f94247ecd9a3be9.mov")!,
//                postedBy: user
//            )
//            
//            return VideoPlayerView(
//                video: video,
//                isPlaying: $isPlaying,
//                isMuted: $isMuted,
//                showHeader: $showHeader,
//                index: 0,
//                currentIndex: $currentIndex
//            )
//        }
//    }


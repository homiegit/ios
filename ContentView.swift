import SwiftUI
import _PhotosUI_SwiftUI
import AVKit
import WebKit

class ViewRouter: ObservableObject {
    @Published var path: [String] = [] {
        didSet {
            print("ViewRouter.path changed to:", path)
        }
    }
    @Published var isVideoSaved = false

    @Published var recordedURLs: [IdentifiableURL] = [] {
        didSet {
            print("viewModel recordedURLs set to", recordedURLs)
        }
    }
    @Published var concatenatedURL: URL? = URL(string: "") {
        didSet {
            print("viewRouter.concatenatedURL set to:", concatenatedURL as Any)
        }
    }
    @Published var topic: String = ""
    @Published var caption: String?
    @Published var bibleSources: [UserBibleSource]?
    @Published var urlSources: [UserUrlSource]?

    @Published var selectedTopics: [String]?
    @Published var selectedVideos: [PhotosPickerItem] = [] {
        didSet {
            print("selectedVideos set to:", selectedVideos)
        }
    }
    @Published  var selectedVideoURLs: [URL]? {
        didSet {
            print("selectedVideoURLs set to:", selectedVideoURLs as Any)
            //self.popToView("EditRecordedClipsView", atIndex: 1)
        }
    }
    @Published var showVideoPicker: Bool = false
    
    @State var viewsList: [Views] = [
        Views(name: "ChatView", view: AnyView(ChatView())),
        Views(name: "UploadView", view: AnyView(UploadView()))
    ]
    
    func popToView(_ viewName: String, atIndex index: Int = 0) {
        path.insert(viewName, at: index)
    }
    
    func popToContentView() { path.removeAll() }

    func popToLast() { path.removeLast() }
}

struct Views {
    var name: String
    var view: AnyView
}

extension Views: Equatable {
    static func == (lhs: Views, rhs: Views) -> Bool {
        return lhs.name == rhs.name
    }
}

extension Views: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

class ContentViewModel: ObservableObject {
    @Published var videos: [Video] = [] {
        didSet {
            // Update isPlayingArray when videos array changes
            print("viewModel.videos.count:", videos.count)
            isPlayingArray = Array(repeating: true, count: videos.count)
        }
    }
    @Published var words: [Word] = []
    @Published var usersMapping: [String: IUser] = [:]
    @Published var usersSet: Bool = false
    @Published var showHeader: Bool = true
    @Published var currentIndex: Int = 0 {
        didSet {
            print("viewModel.currentIndex set to:", currentIndex as Any)
        }
    }
    @Published var isPlayingArray: [Bool] = [] {
        didSet {
            print("isPlayingArray set to:", isPlayingArray)
        }
    }
    @Published var isMuted: Bool = false

    @Published var singleProfileRef: String = ""
    @Published var singleProfileUserData: UserData? {
        didSet {
            print("singleProfileUserData set to:", singleProfileUserData as Any)
        }
    }
    @Published var singleProfileCurrentIndex: Int = 0
    @Published var singleProfileUserSet: Bool = false
    
    @Published var singleVideo: Video?
    @Published var singleVideoUser: IUser?

//    init() {
//        // Initialize isPlayingArray with the same number of elements as videos
//        isPlayingArray = Array(repeating: false, count: videos.count)
//    }
    @Published var preferredVersion: String = "ASV"
    @Published var bibleSource: BibleSource?

}

class TopicsViewModel: ObservableObject {
    @Published var topics: [Topic] = [
        Topic(name: "Jesus"),
        Topic(name: "Torah"),
        Topic(name: "Prophecies"),
        Topic(name: "Scripture"),
        Topic(name: "Gospels"),
        Topic(name: "Revelation"),
        Topic(name: "End of Days"),
        Topic(name: "Testimonies"),
        Topic(name: "Miracles"),
        Topic(name: "Correcting False Teachings")
    ]
    @Published var jesusData: TopicData? = nil
    @Published var torahData: TopicData? = nil
    @Published var propheciesData: TopicData? = nil
    @Published var scriptureData: TopicData? = nil
    @Published var gospelsData: TopicData? = nil
    @Published var revelationData: TopicData? = nil
    @Published var endOfDaysData: TopicData? = nil
    @Published var testimoniesData: TopicData? = nil
    @Published var miraclesData: TopicData? = nil
    @Published var correctingFalseTeachingsData: TopicData? = nil
}


struct WebView: UIViewRepresentable {
    let htmlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }
    }
}

struct OpenVideoPlayerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        
        DispatchQueue.main.async {
            guard let videoURL = self.createLocalUrl(for: "graduallySped2", ofType: "mp4") else {
                print("OpeningViewController: Video file not found")
                return
            }

            // Create an AVPlayer, passing it the local video URL path
            let player = AVPlayer(url: videoURL as URL)
            playerViewController.player = player
            playerViewController.allowsPictureInPicturePlayback = false
            player.play() // Start video playback
            playerViewController.showsPlaybackControls = false

            // Set video player background color (if needed)
            playerViewController.view.backgroundColor = .clear
        }
        
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Implement any updates here if needed
    }
    
    func createLocalUrl(for filename: String, ofType: String) -> URL? {
        // Ensure that URL creation is done on the main thread
        if Thread.isMainThread {
            print("OpeningViewController: Main thread")
            return createURL(for: filename, ofType: ofType)
        } else {
            print("OpeningViewController: Not on the main thread")
            var videoURL: URL?
            DispatchQueue.main.sync {
                videoURL = createURL(for: filename, ofType: ofType)
            }
            return videoURL
        }
    }
    
    private func createURL(for filename: String, ofType: String) -> URL? {
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = cacheDirectory.appendingPathComponent("\(filename).\(ofType)")
        print("OpeningViewController: URL: \(url)")
        guard fileManager.fileExists(atPath: url.path) else {
            guard let video = NSDataAsset(name: filename)  else { return nil }
            fileManager.createFile(atPath: url.path, contents: video.data, attributes: nil)
            return url
        }
        
        return url
    }
}

public var screenHeight: CGFloat = UIScreen.main.bounds.height
public var screenWidth: CGFloat = UIScreen.main.bounds.width

struct ContentView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @StateObject private var viewModel = ContentViewModel()
    @EnvironmentObject var topicsViewModel: TopicsViewModel


    //@State private var showVideos: Bool = true
    //@State private var showWords: Bool = false

    @State private var userImage: UIImage?
    @Binding var secondsWatched: Int
    @State var showHeader: Bool = true
    @State private var currentLoopControl: String = "loop"
    @Binding var currentPlayerTime: Double
    @State var refreshed: Bool = false
    var videoURL: URL? = Bundle.main.url(forResource: "graduallySped", withExtension: "mov")

    init(secondsWatched: Binding<Int> = .constant(0), currentPlayerTime: Binding<Double> = .constant(Double(0))) {
        self._secondsWatched = secondsWatched
        self._currentPlayerTime = currentPlayerTime
    }
    
    var imageURL: URL? = Bundle.main.url(forResource: "JWST", withExtension: "jpg")
    
    @State var videoSize: Double = 0.01 {
        didSet {
            print("videoSize:", videoSize)
        }
    }
    @State var videoPositionY: CGFloat = screenHeight / 1.2
    @State var isReadyToPlay: Bool = false

    @State private var previousTranslation: CGSize = .zero {
        didSet {
            print("previousTranslation:", previousTranslation)
        }
    }

    // Define a computed property to calculate the aspect ratio
    private var aspectRatio: CGFloat {
        let width = UIScreen.main.bounds.width / 1
        let height = UIScreen.main.bounds.height / 3.5
        return width / height
    }
    
    var body: some View {
        NavigationStack(path: $viewRouter.path) {
            ZStack(alignment: .top) {
//                AsyncImage(url: imageURL) { phase in
//                    switch phase {
//                    case .empty:
//                        Color.cyan // Placeholder when the image is not loaded yet
//                    case .success(let image):
//                        image
//                            .resizable()
//                            .scaledToFill()
//                            .frame(maxWidth: .infinity, maxHeight: .infinity)
//                            .edgesIgnoringSafeArea(.all)
//                    case .failure:
//                        Color.red // Placeholder when the image loading fails
//                    @unknown default:
//                        Color.gray
//                    }
//                }
                
                
//                Image("JWST")
//                    .resizable()
//                    .scaledToFill()
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .edgesIgnoringSafeArea(.all)
                
                
//                WebView(htmlString: """
//                    <div style="width:100%;height:0;padding-bottom:100%;position:relative;">
//                        <iframe src="https://giphy.com/embed/fl41FRYRvhzOgiyDkX" width="100%" height="100%" style="position:absolute" frameBorder="0" class="giphy-embed" allowFullScreen></iframe>
//                    </div>
//                    <p><a href="https://giphy.com/gifs/europeanspaceagency-space-esa-european-agency-fl41FRYRvhzOgiyDkX">via GIPHY</a></p>
//                """)
                //.frame(width: 480, height: 480)
                if viewModel.videos.isEmpty || viewModel.currentIndex >= viewModel.videos.count{
                    Image("firstFrame")
                        .resizable()
                        //.scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                }
                if viewModel.currentIndex < viewModel.videos.count {
                    if viewModel.videos[viewModel.currentIndex].isVideoReliable.reliability == "false" {
                        Image("earth-core")
                            .resizable()
                        //.scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .edgesIgnoringSafeArea(.all)
                        
                    } else {
                        OpenVideoPlayerView()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight:  .infinity)
                            .edgesIgnoringSafeArea(.all)
                    }
                }
                
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Button(action: {
                            //if showVideos {
                                refreshVideos()
                            //} else if showWords {
                                //refreshWords()
                            //}
                        }) {
                            Image("homie-banner")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 50)
                        }
                       //Spacer()
                        
                        Button(action: {
                            viewRouter.popToView("BibleView", atIndex: viewRouter.path.count)
                        }) {
                            Image(systemName: "a.book.closed.fill")
                                .font(.system(size: 35))
                                .foregroundColor(.purple)
                                //.background(Color.secondary)
                        }

                        //Spacer()
                        
                        Button(action:  {
                            viewRouter.popToView("UploadView", atIndex: viewRouter.path.count)
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 35))
                                .foregroundColor(.pink)
                       }
                        //Spacer()
                        
                        Button(action:  {
                            viewRouter.popToView("WhoIsLiveView", atIndex: viewRouter.path.count)
                        }) {
                            Text("Live")
                                .font(.system(size: 25))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)

                                .foregroundColor(Color.black)
                                .background(Color.accentColor)
                                .cornerRadius(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 5) // Border
                                )
                       }
                        //Spacer()
                        
                        Button(action: {
                            viewRouter.popToView("SearchView", atIndex: viewRouter.path.count)
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 35))
                                .foregroundColor(Color.accentColor)
                            }
                        //Spacer()
                        
                        Button(action: {
                            if UserDefaults.userProfile != nil && UserDefaults.userProfile?._id != "" {
                                if let userId = UserDefaults.userProfile?._id {
                                    viewModel.singleProfileRef = userId
                                    viewRouter.popToView("ProfileView", atIndex: viewRouter.path.count)
                                }
                            } else {
                                viewRouter.popToView("SignInView", atIndex: viewRouter.path.count)
                            }
                        }) {
                            if let userImage = UserDefaults.image?.url {
                                if userImage != "" {
                                    AsyncImage(url: URL(string: userImage)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 45, height: 45)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        EmptyView()
                                    }
                                } else {
                                    Image("default")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 45, height: 45)
                                        .clipShape(Circle())
                                }

                            } else {
                                Image("default")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 45, height: 45)
                                    .clipShape(Circle())
                            }
                        }
                    }

                    .frame(height: 69)
                    .background(Color.clear)
//                        ScrollViewReader { videoScrollProxy in
                            //ScrollView(.vertical) {
                    VStack {
//                            Text("\(String(describing: viewModel.currentIndex))")
//                                .foregroundColor(.white)
//                                .bold()

                            contentForVideo(at: viewModel.currentIndex, currentLoopControl: $currentLoopControl, path: viewRouter.path)
   
                    }
                        //.scaleEffect(CGFloat(videoSize))
                        //.frame(width: geometry.size.width * videoSize, height: geometry.size.width * videoSize )
                    
//                                .id("videoScrollView")
                                
                            //}
//                            .gesture(
//                                DragGesture(minimumDistance: 50)
//                                    .onEnded { gesture in
//                                        print("gesture:", gesture)
//                                        if gesture.translation.height > 0 {
//                                            DispatchQueue.main.async {
//                                                if let currentIndex = viewModel.currentIndex,
//                                                   currentIndex < viewModel.videos.count {
//                                                    viewModel.currentIndex = currentIndex + 1
//                                                } else if let currentIndex = viewModel.currentIndex,
//                                                          currentIndex == viewModel.videos.count {
//                                                    print("last index")
//                                                }
//                                            }
//                                            videoScrollProxy.scrollTo(viewModel.currentIndex)
//                                        }
//                                    }
//                            )

                        //}
                        //.background(Color.clear)

                }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { gesture in
                         print("gesture:", gesture.translation.height)
                         
                         // Calculate the change in translation since the last update
                         let translationChange = CGSize(
                             width: gesture.translation.width - previousTranslation.width,
                             height: gesture.translation.height - previousTranslation.height
                         )
                         
                         // Adjust the scale factor based on gesture translation
                         let scaleDelta = Double(translationChange.height) / 300
                         let newVideoSize = videoSize + scaleDelta
                         
                         // Clamp the newVideoSize between 0.001 and 1
                         videoSize = min(max(newVideoSize, 0.001), 1.0)
                         
                         if gesture.translation.height > 0 && videoPositionY >= screenHeight / 1.2 {
                             let positionDelta = translationChange.height / 1
                             let newVideoPositionY = videoPositionY + positionDelta
                             
                             videoPositionY = min(max(newVideoPositionY, UIScreen.main.bounds.height / 1.2), UIScreen.main.bounds.height / 0.5)
                         } else {
                             videoPositionY = screenHeight / 1.2
                         }
                         
                         // Update the previous translation
                         previousTranslation = gesture.translation
                     }
                     .onEnded { _ in
                         // Reset the previous translation when the drag ends
                         previousTranslation = .zero
                     }
                    .onEnded { endGesture in
                        if endGesture.translation.height < -40 || videoSize <= 0.5 {
                            if viewModel.currentIndex != viewModel.videos.count - 1 {
                                if viewModel.videos.count != 0 {
                                    DispatchQueue.main.async {
                                        print("currentIndex forward")
                                        isReadyToPlay = false

                                        viewModel.isPlayingArray[viewModel.currentIndex] = false
                                        
                                        if viewModel.currentIndex < viewModel.videos.count - 1 {
                                            viewModel.isPlayingArray[viewModel.currentIndex + 1] = true
                                            viewModel.currentIndex += 1
                                        }
                                        
                                        Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { timer in
                                            withAnimation(Animation.linear(duration: 2.0)) {
                                                videoSize = min(max(videoSize - 1.0, 0.001), 1.0)
                                            }
                                            if videoSize <= 0.001 {
                                                timer.invalidate()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if endGesture.translation.height >= 40 || videoPositionY >= screenHeight / 0.6 {
                            if viewModel.currentIndex != 0 {
                                DispatchQueue.main.async {
                                    print("currentIndex back")
                                    isReadyToPlay = false
                                    
                                    viewModel.isPlayingArray[viewModel.currentIndex] = false
                                    viewModel.isPlayingArray[viewModel.currentIndex - 1] = true
                                    if viewModel.currentIndex < viewModel.videos.count {
                                        viewModel.currentIndex -= 1
                                    }
                                    
                                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                                        withAnimation(Animation.linear(duration: 4.0)) {
                                            videoPositionY += CGFloat(0.1)
                                            
                                        }
                                        if videoPositionY <= screenHeight / 0.6 {
                                            timer.invalidate()
                                            videoPositionY = screenHeight / 1.2
                                        }
                                    
                                    }
                                }
                            } else {
                                refreshVideos()
                                videoPositionY = screenHeight / 1.2
                                
                            }
                        }
                        if endGesture.translation.height > 0 && endGesture.translation.height < 40 {

                                    videoPositionY = screenHeight / 1.2

                                
                            
                        }
                        if endGesture.translation.height < 0 && endGesture.translation.height > -40 {
                            videoSize = 1.0
                            videoPositionY = screenHeight / 1.2

                        }
                        
                    }
            )
            .navigationDestination(for: String.self) { viewName -> AnyView in
                switch viewName {
                    case "ChatView": return AnyView(ChatView().environmentObject(viewRouter))
                    case "UploadView": return AnyView(UploadView().environmentObject(viewRouter).environmentObject(viewModel))
                    case "WhoIsLiveView": return AnyView(WhoIsLiveView().environmentObject(viewRouter))
                    case "SearchView": return AnyView(SearchView().environmentObject(viewRouter).environmentObject(topicsViewModel))
                    case "ProfileView": return
                        AnyView(ProfileView().environmentObject(viewRouter).environmentObject(viewModel))
                    case "SettingsView": return AnyView(SettingsView().environmentObject(viewRouter))
                    case "TopicView": return AnyView(TopicView().environmentObject(viewRouter).environmentObject(topicsViewModel))
                    case "SingleVideoView": return AnyView(SingleVideoView().environmentObject(viewRouter).environmentObject(viewModel))
                    case "LiveCaptureVideoView": return AnyView(LiveCaptureVideoView().environmentObject(viewRouter))
                    case "CaptureVideoView": return AnyView(CaptureVideoView().environmentObject(viewRouter))
                    case "EditRecordedClipsView": return AnyView(EditRecordedClipsView().environmentObject(viewRouter).environmentObject(viewModel))
                    case "PostVideoView": return AnyView(PostVideo().environmentObject(viewRouter).environmentObject(viewModel))
                    case "PreviewView": return AnyView(PreviewView().environmentObject(viewRouter).environmentObject(viewModel))
                    case "SignInView": return AnyView(SignInView().environmentObject(viewRouter))
                    case "BibleView": return AnyView(BibleView().environmentObject(viewRouter).environmentObject(viewModel))

                    default: return AnyView(EmptyView())
                }
            }

            //.background(Color.red)
        }
        
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width < 0 {
                        // Leftward swipe detected
                        
                        if viewModel.currentIndex < viewModel.videos.count {
                            DispatchQueue.main.async {
                                viewModel.singleProfileRef = viewModel.videos[viewModel.currentIndex].postedBy._ref
                                viewRouter.popToView("ProfileView", atIndex: viewRouter.path.count)
                            }
                        }
                        
                    } else if value.translation.width > 0 {
                        // Rightward swipe detected
                    }
                }
        )
    }

    @ViewBuilder
    private func contentForVideo(at index: Int, currentLoopControl: Binding<String>, path: [String]) -> some View {
        if index >= 0 && index < viewModel.videos.count {
            let video = viewModel.videos[index]
            
            let userRef = video.postedBy._ref
            if let user = viewModel.usersMapping[userRef] {
                Spacer()
                VideoPlayerView(
                    video: video,
                    user: user,
                    isPlaying: Binding(
                        get: {
                             let currentIndex = viewModel.currentIndex
                            if currentIndex >= 0 && currentIndex < viewModel.isPlayingArray.count {
                                return currentIndex == index && viewModel.isPlayingArray[currentIndex] == true && isReadyToPlay
                            } else {
                                return false // Handle the case where currentIndex is nil or out of range
                            }
                        },
                        set: { newValue in
                            print("set isPlaying value:", newValue)
                            
                            DispatchQueue.main.async {
                                if index >= 0 && index < viewModel.isPlayingArray.count {
                                    //viewModel.currentIndex = newValue ? index : nil
                                    viewModel.isPlayingArray[index] = newValue
                                    
                                } else {
                                    print("Index is out of range for isPlayingArray.")
                                }
                            }
                        }
                    ),
                    currentLoopControl: $currentLoopControl,
                    isMuted: $viewModel.isMuted,
                    showHeader: $showHeader,
                    currentIndex: $viewModel.currentIndex,
                    videoSize: $videoSize,
                    videoPositionY: $videoPositionY
                )
                .id(viewModel.currentIndex)
                .environmentObject(viewModel)
                .environmentObject(viewRouter)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 1.2)
                .onAppear{
                    videoPositionY = screenHeight / 1.2
                    videoSize = 0.01
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) {_ in
                        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                            withAnimation(Animation.linear(duration: 2.0)) {
                                // Increase videoSize gradually from 0.01 to 1.0
                                videoSize = min(max(videoSize + 0.02, 0.001), 1.0)
                            }
                            if videoSize >= 0.50 {
                                // Stop the timer when videoSize reaches 1.0
                                timer.invalidate()
                                
                            }
                        }
                        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer2 in
                            if videoSize >= 0.50 {
                                withAnimation(Animation.linear(duration: 1.0)) {
                                    // Increase videoSize gradually from 0.01 to 1.0
                                    videoSize = min(max(videoSize + 0.015, 0.001), 1.0)
                                }
                            }
                            if videoSize >= 1.0 {
                                
                                timer2.invalidate()
                                isReadyToPlay = true
                            }
                        }
                    }
                }
                .onChange(of: viewModel.currentIndex) { _ in
                    isReadyToPlay = false
                    videoSize = 0.01
                    Timer.scheduledTimer(withTimeInterval: 0.0, repeats: false) {_ in
                        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                            withAnimation(Animation.linear(duration: 2.0)) {
                                // Increase videoSize gradually from 0.01 to 1.0
                                videoSize = min(max(videoSize + 0.02, 0.001), 1.0)
                            }
                            if videoSize >= 0.50 {
                                // Stop the timer when videoSize reaches 1.0
                                timer.invalidate()
                                
                            }
                        }
                        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer2 in
                            if videoSize >= 0.50 {
                                withAnimation(Animation.linear(duration: 2.0)) {
                                    // Increase videoSize gradually from 0.01 to 1.0
                                    videoSize = min(max(videoSize + 0.015, 0.001), 1.0)
                                }
                            }
                            if videoSize >= 1.0 {
                                
                                timer2.invalidate()
                                isReadyToPlay = true
                            }
                        }
                    }
                }
//                .overlay (
//                    Text("\(String(describing: video))")
//                        .foregroundColor(.white).bold()
//                )
            } else {
                Text("No users")
                    .foregroundColor(.gray)
                    .padding()
                
            }
        } else {
            Text("No videos available")
                .foregroundColor(.gray)
                .padding()
        }
    }

    private func updateIsPlayingArray(at index: Int, newValue: Bool) {
        print("updating", index, "isplaying to:", newValue)
        //print("index in updateisplayingarray", index)
        if index >= 0 && index < viewModel.isPlayingArray.count {
             DispatchQueue.main.async {
                 viewModel.isPlayingArray[index] = newValue
             }
         } else {
             print("Index is out of range for isPlayingArray.")
         }
    }
    
    private func fetchUsers(forRefs _refs: [String]) {
        UsersFromPosts().fetchUsers(forRefs: _refs) { fetchedUsers in
            DispatchQueue.main.async {
                // Update the users mapping on the main thread
                let usersMapping = Dictionary(uniqueKeysWithValues: fetchedUsers.map { ($0._id, $0) })
                viewModel.usersMapping = usersMapping
                viewModel.usersSet = true
            }
        }
    }

    private func refreshVideos() {
        refreshed = true
        isReadyToPlay = false
        DispatchQueue.main.async {
            viewModel.videos = []
            viewModel.currentIndex = 0
        }
        videoSize = 0.01

        Refresh().refreshVideos() { videoData in
            DispatchQueue.main.async {
                // Update the videos on the main thread
                viewModel.videos = videoData
                
                // Fetch users after updating videos
                let userRefs = viewModel.videos.map(\.postedBy._ref)
                fetchUsers(forRefs: userRefs)
                refreshed = false
            }
        }
    }

    private func refreshWords() {
        Refresh().refreshWords() { wordData in
            DispatchQueue.main.async {
                // Update the words on the main thread
                viewModel.words = wordData
                
                // Fetch users after updating words
                let userRefs = viewModel.words.map(\.postedBy._ref)
                fetchUsers(forRefs: userRefs)
            }
        }
    }

}
                
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(
//            videos: [
//                Video(
//                    _type: "video",
//                    isVideoReliable: Video.IsVideoReliable(
//                        reliability: "pending",
//                        proof: []
//                    ),
//                    isFeatured: true,
//                    videoUrl: URL(string: "https://cdn.sanity.io/files/ynqkzz99/production/62541e33cd77cb12f81ef387ab18f059db36d8d9.mp4"),
//                    caption: "God told me “Record what you saw”",
//                    userSources: [],
//                    selectedTopics: ["Testimonies", "EndofDays"],
//                    transcriptionResults: "https://s3.us-west-2.amazonaws.com/outputtranscribebucket2/job-1690224429622.json",
//                    cues: [
//                        Items(
//                            alternatives: [
//                                Items.Alternative(
//                                    confidence: 0.999,
//                                    content: "I",
//                                    _key: "09d800e4-7e30-472e-a5a4-e478092d3458"
//                                )
//                            ],
//                            start_time: 0.009,
//                            end_time: 0.1,
//                            _key: "a071c6a5-5505-479a-a523-4f7060192295"
//                        ),
//                        Items(
//                            alternatives: [
//                                Items.Alternative(
//                                    confidence: 0.999,
//                                    content: "woke",
//                                    _key: "ba46b759-5f54-443f-b2ea-75be91d22ec5"
//                                )
//                            ],
//                            start_time: 0.589,
//                            end_time: 0.86,
//                            _key: "2f462369-fb8b-41ef-84ea-aa82734a6ee2"
//                        ),
//                        Items(
//                            alternatives: [
//                                Items.Alternative(
//                                    confidence: 0.999,
//                                    content: "up",
//                                    _key: "c151e69f-f4f7-4d6e-bb9a-e1beb94ac56b"
//                                )
//                            ],
//                            start_time: 0.87,
//                            end_time: 1.379,
//                            _key: "60cdb51e-16db-4172-9c20-4a34bc35514d"
//                        ),
//                        Items(
//                            alternatives: [
//                                Items.Alternative(
//                                    confidence: 0.999,
//                                    content: "out",
//                                    _key: "c12c4f70-4962-4673-80c3-bf1edc0ed2ca"
//                                )
//                            ],
//                            start_time: 2.309,
//                            end_time: 2.64,
//                            _key: "3da18b4f-38c3-455a-b6ff-ba4a5cc3150d"
//                        ),
//                        Items(
//                            alternatives: [
//                                Items.Alternative(
//                                    confidence: 0.999,
//                                    content: "of",
//                                    _key: "621e9b8f-8eeb-4cd2-84ea-03efe8a6ec0d"
//                                )
//                            ],
//                            start_time: 2.65,
//                            end_time: 2.809,
//                            _key: "ca44018d-83df-49e4-8ec5-e2c1a43a2642"
//                        ),
//                        Items(
//                            alternatives: [
//                                Items.Alternative(
//                                    confidence: 0.996,
//                                    content: "a",
//                                    _key: "ff10fbce-1f70-4d9c-ac56-10f16d5cfccb"
//                                )
//                            ],
//                            start_time: 2.819,
//                            end_time: 2.829,
//                            _key: "c6cd876f-d22a-4523-ab80-e01be16795df"
//                        ),
//                        Items(
//                            alternatives: [
//                                Items.Alternative(
//                                    confidence: 0.999,
//                                    content: "dream",
//                                    _key: "67b191d5-9cbe-4b54-9a72-324ddb693076"
//                                )
//                            ],
//                            start_time: 2.839,
//                            end_time: 3.579,
//                            _key: "29de51f0-f1d8-4de2-8466-d5eafda7d8f7"
//                        )                    ],
//                    transcription: "I just woke up out of a dream.",
//                    onlyWordsTranscription: [
//                        "I",
//                        "just",
//                        "woke",
//                        "up",
//                        "out",
//                        "of",
//                        "a",
//                        "dream"
//                    ],
//                    translatedText: "",
//                    claims: [],
//                    videoId: "0w3lID6Lsk7VK2mhOMtWdb",
//                    createdAt: "July 24, 2023 at 11:42 AM",
//                    timeAgo: nil,
//                    video: VideoAsset(asset: Asset(_type: "file", _ref: "file-62541e33cd77cb12f81ef387ab18f059db36d8d9-mp4"), videoUrl: URL(string: "https://cdn.sanity.io/files/ynqkzz99/production/62541e33cd77cb12f81ef387ab18f059db36d8d9.mp4")!),
//                    _id: "0w3lID6Lsk7VK2mhOMtWdb",
//                    postedBy: PostedBy(_ref: "e3914959-8862-4bd6-9eac-91ca611b6454"),
//                    likes: [],
//                    comments: []
//                )
//            ],
//            usersMapping: [
//                "e3914959-8862-4bd6-9eac-91ca611b6454": IUser(id: "e3914959-8862-4bd6-9eac-91ca611b6454", _id: "e3914959-8862-4bd6-9eac-91ca611b6454", _type: "user", userName: "lady1", image: IUser.Image(asset: IUser.Image.Asset(_ref: "", _type: "reference"), _type: "image", url: ""), isUserReliable: IUser.IsUserReliable(reliability: "pending", proof: []))
//                ],
//            isPlayingArray: Array(repeating: false, count: 1)
//
//        )
//        .environmentObject(ViewRouter())
//    }
//}

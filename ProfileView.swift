import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @EnvironmentObject var viewModel: ContentViewModel
    
    @State private var showVideos = true
    @State private var showWords = false
    @State private var activeSelection = "videos"
    //@State private var videos: [Video] = []
//    @State private var words: [Word] = []
//    @State private var user: IUser? {
//        didSet {
//            print("user set to: ", user ?? "")
//        }
//    }
    //@State private var counts: Counts?

    @State private var userSet: Bool = false
    @State private var showHeader: Bool = false
    @State private var currentIndex: Int? = nil
    @State private var globalIsPlaying = false
    @State private var videoPostedByUsers: [IUser] = []
    @State private var wordPostedByUsers: [IUser] = []
    @State private var data: [String: Any] = [:]

    @State private var showStats = false
    @State private var showVideosScrollView = false
    @State private var userImage: UIImage?
    @State private var showChangeImage = false
    @State private var showChangeUserName = false
    @State private var userNameExists = false
    @State private var newUserName = ""
    @State private var password = ""
    @State private var showActions: [String: Bool] = [:]
    @State private var showDelete: [String: Bool] = [:]
    
    @State private var isMuted = true
    @State private var isPlaying = true
    @State private var currentLoopControl: String = "loop"
    @Binding private var secondsWatched: Int
    
    @State private var showSettings: Bool = false
    @State private var userId: String = ""
    
    init(secondsWatched: Binding<Int> = .constant(0)) {
        self._secondsWatched = secondsWatched
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                if let userImage = viewModel.singleProfileUserData?.user.image?.url {
                    AsyncImage(url: URL(string: userImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 55, height: 55)
                            .clipShape(Circle())
                    } placeholder: {
                        EmptyView()
                    }

                    
                } else {
                    Image("default")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 55, height: 55)
                        .clipShape(Circle())
                }
                if let username = viewModel.singleProfileUserData?.user.userName {
                    Text(username)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
            }
            .onAppear {
                userId = viewModel.singleProfileRef
                print("userId:", userId)
                ProfileData().fetchUserData(userId) { result in
                    switch result {
                    case .success(let profileData):
                        print("profileData:", profileData)
                        DispatchQueue.main.async {
                            viewModel.singleProfileUserData = UserData(videos: profileData.videos, user: profileData.user, counts: profileData.counts)
                            viewModel.singleProfileUserSet = false
                            viewModel.singleProfileUserSet = true
                            viewModel.isPlayingArray = []
                        }
                    case .failure(let error):
                        print("Error fetching data:", error)
                    }
                }
            }
            //.frame(height: 100)
            .overlay(
                HStack {
                    Spacer()
                    VStack {
                        if userId == UserDefaults.userProfile?._id {
                            Button(action: {
                                viewRouter.popToView("SettingsView", atIndex: 1)
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 25))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 5)
                            
                            Button(action: {
                                showStats.toggle()
                            }) {
                                Image(systemName: "chart.pie")
                                    .font(.system(size: 25))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 5)
                            
                        }
                    }
                }
            )
            
            if showStats {
                VStack {
                    Text("Your stats")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                    if let counts = viewModel.singleProfileUserData?.counts {
                         let countProperties: [(String, Int?)] = [
                             ("wordPercentTrue", counts.wordPercentTrue),
                             ("totalWordsCount", counts.totalWordsCount),
                             ("reliableWordsCount", counts.reliableWordsCount),
                             ("inaccurateWordsCount", counts.inaccurateWordsCount),
                             ("pendingWordsCount", counts.pendingWordsCount),
                             ("falseWordsCount", counts.falseWordsCount),
                             ("videoPercentTrue", counts.videoPercentTrue),
                             ("totalVideosCount", counts.totalVideosCount),
                             ("reliableVideosCount", counts.reliableVideosCount),
                             ("inaccurateVideosCount", counts.inaccurateVideosCount),
                             ("pendingVideosCount", counts.pendingVideosCount),
                             ("falseVideosCount", counts.falseVideosCount),
                             ("allPerReviewed", counts.allPerReviewed),
                             ("allTotalReviewed", counts.allTotalReviewed),
                             ("trueVideosPerReviewed", counts.trueVideosPerReviewed),
                             ("trueWordsPerReviewed", counts.trueWordsPerReviewed),
                             ("allPercentTrue", counts.allPercentTrue),
                             ("countedTrueReviewed", counts.countedTrueReviewed)
                         ]

                         ForEach(countProperties, id: \.0) { propertyName, value in
                             if let value = value {
                                 Text("\(propertyName): \(value)")
                                     .foregroundColor(.white)
                                     .font(.system(size: 15))
                             }
                         }
                     }
                }
            }
            
            Divider()
                .background(Color.gray)
                .frame(width: UIScreen.main.bounds.width / 1.2)
            
            if showVideosScrollView && viewModel.singleProfileUserSet, let videos = viewModel.singleProfileUserData?.videos {
                    ScrollViewReader {scrollViewProxy in
                        ScrollView {
                            ForEach(videos.indices, id: \.self) { index in
                                contentForVideo(at: index, path: viewRouter.path)
                                    .id(index)
                                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 1.2)
                            }
                        }
                        .onChange(of: viewModel.singleProfileCurrentIndex) {index in
                            print("newIndex:", index as Any)
                           scrollViewProxy.scrollTo(index)
                        }
                        .gesture(
                            DragGesture(minimumDistance: 50)
                                .onEnded { gesture in
                                if gesture.translation.width > 0 {
                                    showVideosScrollView = false
                                }
                            }
                        )
                    
//                    .onDisappear{
//                        showVideosScrollView = false
//                    }
                }

            }
            if !showVideosScrollView {
                if let videos = viewModel.singleProfileUserData?.videos {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: UIScreen.main.bounds.width * 0.33))], spacing: 3) {
                            GeometryReader { geometry in
                                ForEach(videos.indices, id: \.self) { index in
                                    let video = videos[index]
                                    
                                    Button(action: {
                                        DispatchQueue.main.async {
                                            viewModel.singleProfileCurrentIndex = index
                                        }
                                        showVideosScrollView = true

                                    }) {
                                        PreviewVideoPlayerView(video: video, isPlaying: $isPlaying, isMuted: $isMuted)
                                            .overlay(
                                                VStack {
                                                    Spacer()
                                                    HStack {
                                                        Spacer()
                                                        Text("\(video.views?.count ?? 0)")
                                                            .font(.system(size: 15))
                                                            .foregroundColor(.white)
                                                            .padding(.trailing, -5)
                                                        Image(systemName: "play")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(.white)
                                                        
                                                    }
                                                    .frame(alignment: .trailing)
                                                    .padding(.trailing, 10)
                                                }
                                            )
                                        //                                            .frame(width: UIScreen.main.bounds.width * 0.33, height: UIScreen.main.bounds.height * 0.33)
                                    }
                                    
                                }
                                //                                .background(
                                //                                    GeometryReader { geometry in
                                //                                        Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
                                //                                    }
                                //                                )
                            }
                            //                            .onPreferenceChange(SizePreferenceKey.self) { size in
                            //                                // Save the size information here if needed
                            //                                print(size)
                            //                            }
                            
                        }
                        .padding()
                        .background(Color.black)
                        
                        //                if showWords {
                        //                    ScrollView(.vertical) {
                        //                        Group { // Wrap VStack inside a Group
                        //                            VStack(spacing: 35) {
                        //                                if userSet {
                        //
                        //                                    ForEach(words.indices, id: \.self) { index in
                        //                                        WordView(
                        //                                            word: words[index],
                        //                                            user: user!
                        //                                        )
                        //
                        //                                    }
                        //                                }
                        //                                Spacer()
                        //                            }
                        //                        }
                        //                        .padding(15.0)
                        //                        .background(Color.black)
                        //                        .id(viewModel.singleProfileUserSet) // Use .id() to trigger view update
                        //                    }
                        //                }
                    }
                }
            }
//            .id("")
        }
//        .gesture(
//            DragGesture(minimumDistance: 50, coordinateSpace: .local)
//                .onEnded { value in
//                    if value.translation.width < 0 {
//                        // Leftward swipe detected, switch to words view
//                        showWords = true
//                        showVideos = false
//                    } else if value.translation.width > 0 {
//                        // Rightward swipe detected, switch back to videos view
//                        showWords = false
//                        showVideos = true
//                    }
//                }
//        )
        .background(Color.black)
        .navigationBarBackButtonHidden(true)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded {gesture in
                    if gesture.translation.width > 0 {
                        DispatchQueue.main.async {
                            viewRouter.popToLast()
                        }
                }
            }
        )
    }
    
//    private func getNonNilCounts() -> [(label: String, value: Int)] {
//        var nonNilCounts: [(label: String, value: Int)] = []
//
//        // Safely unwrap the optional Counts
//        if let unwrappedCounts = counts {
//            // Use Mirror to loop through the properties of Counts
//            let mirror = Mirror(reflecting: unwrappedCounts)
//            for child in mirror.children {
//                if let value = child.value as? Int, let label = child.label {
//                    nonNilCounts.append((label: label, value: value))
//                }
//            }
//        }
//
//        return nonNilCounts
//    }
    
    @ViewBuilder
    private func contentForVideo(at index: Int, path: [String]) -> some View {
        if let video = viewModel.singleProfileUserData?.videos[index], let userData =  viewModel.singleProfileUserData {
//            VideoPlayerView(
//                video: video,
//                user: userData.user,
//                isPlaying: Binding(
//                    get: {
//                        viewModel.singleProfileCurrentIndex == index
//                    },
//                    set: { newValue in
//                        print("new viewModel.currentIndex Value:", newValue)
//                        updateIsPlayingArray(at: index, newValue: newValue)
//                        DispatchQueue.main.async {
//                            viewModel.singleProfileCurrentIndex = newValue ? index : nil
//                        }
//                    }
//                ),
//                currentLoopControl: $currentLoopControl,
//                isMuted: $viewModel.isMuted,
//                showHeader: $showHeader,
//                currentIndex: $viewModel.singleProfileCurrentIndex
//            )
//            .environmentObject(viewModel)
//            .environmentObject(viewRouter)
        }
    }

    private func updateIsPlayingArray(at index: Int, newValue: Bool) {
        DispatchQueue.main.async {
            viewModel.isPlayingArray.indices.forEach { i in
                viewModel.isPlayingArray[i] = (i == index) && newValue
            }
        }
    }

    // Create a custom preference key to capture the size of VideoPlayerView
    struct SizePreferenceKey: PreferenceKey {
        typealias Value = CGSize

        static var defaultValue: CGSize = .zero

        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
        
    func deleteDocument(_ id: String) {
        // Implement your deleteDocument logic here...
    }

}

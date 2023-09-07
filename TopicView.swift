import SwiftUI

struct TopicData: Codable {
    var video: [Video]
    var word: [Word]
    var user: [IUser]
}

struct TopicView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @EnvironmentObject var topicsViewModel: TopicsViewModel
    //let topic: String

    @State private var topicVideos: Video?
    @State private var topicWords: Word?
    @State private var topicUsers: IUser?

    @State private var topicData: TopicData? = nil

    @State private var noData: Bool = false
    
    @State private var isPlaying: Bool = true
    @State private var currentLoopControl: String = "loop"
    @State private var isMuted: Bool = true
    @State private var showHeader: Bool = true
    @State private var currentIndex: Int? = nil
    @Binding var secondsWatched: Int
    @Binding var viewAddedAlready: Bool
    
    init(secondsWatched: Binding<Int> = .constant(0), viewAddedAlready: Binding<Bool> = .constant(false)) {
        _secondsWatched = secondsWatched
        _viewAddedAlready = viewAddedAlready
    }
    var body: some View {
        ZStack(alignment: .top) {
            Color.black
            Text(viewRouter.topic)
                .foregroundColor(Color.blue)
                .font(.system(size: 40))
            //Spacer()
            ScrollView {
                ScrollView(.horizontal) {
                    HStack {
                        if let topicData = topicData {
                            ForEach(topicData.video.indices, id: \.self) {index in
//                                Button(action: {
//                                    viewRouter.popToView("SingleVideoView", atIndex: 2)
//                                }) {
//                                    EmptyView()
//                                    VideoPlayerView(
//                                        video: topicData.video[index],
//                                        user: topicData.user[index],
//                                        isPlaying: $isPlaying,
//                                        currentLoopControl: $currentLoopControl,
//                                        isMuted: $isMuted,
//                                        showHeader: $showHeader,
//                                        currentIndex: $currentIndex
//                                        //secondsWatched: $secondsWatched,
//                                    )
//                                    .frame(width: UIScreen.main.bounds.width / 3, height: UIScreen.main.bounds.height / 3)
////                                    .onDisappear{
////                                        UpdateViewAndSecondsWatched().updateViewAndSecondsWatched(videoId: <#T##String#>, secondsWatched: <#T##Int#>, isViewAddedAlready: <#T##Bool#>, completion: <#T##(Result<Data, Error>) -> Void#>)
////                                    }
//                                }
                            }
                        }
                    }
                }
//                ScrollView(.horizontal) {
//                    HStack {
//                        if let topic: String = viewRouter.topic {
//                            switch topic {
//                            case "Jesus":
//                                if let topicData = topicsViewModel.jesusData {
//                                    ForEach(topicData.word.indices, id: \.self) { index in
//                                        WordView(
//                                            word: topicData.word[index],
//                                            user: topicData.user[index]
//                                        )
//                                    }
//                                }
//                            case "Torah":
//                                if let topicData = topicsViewModel.torahData {
//                                    ForEach(topicData.word.indices, id: \.self) { index in
//                                        WordView(
//                                            word: topicData.word[index],
//                                            user: topicData.user[index]
//                                        )
//                                    }
//                                }
//                            case "Prophecies":
//                                if let topicData = topicsViewModel.propheciesData {
//                                    ForEach(topicData.word.indices, id: \.self) { index in
//                                        WordView(
//                                            word: topicData.word[index],
//                                            user: topicData.user[index]
//                                        )
//                                    }
//                                }
//                            case "Scripture":
//                                if let topicData = topicsViewModel.scriptureData {
//                                    ForEach(topicData.word.indices, id: \.self) { index in
//                                        WordView(
//                                            word: topicData.word[index],
//                                            user: topicData.user[index]
//                                        )
//                                    }
//                                }
//                            case "Gospels":
//                                if let topicData = topicsViewModel.gospelsData {
//                                    ForEach(topicData.word.indices, id: \.self) { index in
//                                        WordView(
//                                            word: topicData.word[index],
//                                            user: topicData.user[index]
//                                        )
//                                    }
//                                }
//                            case "Revelation":
//                                if let topicData = topicsViewModel.revelationData {
//                                    ForEach(topicData.word.indices, id: \.self) { index in
//                                        WordView(
//                                            word: topicData.word[index],
//                                            user: topicData.user[index]
//                                        )
//                                    }
//                                }
//                            case "End of Days":
//                                if let topicData = topicsViewModel.endOfDaysData {
//                                    ForEach(topicData.word.indices, id: \.self) { index in
//                                        WordView(
//                                            word: topicData.word[index],
//                                            user: topicData.user[index]
//                                        )
//                                    }
//                                }
//                            case "Testimonies":
//                                if let topicData = topicsViewModel.testimoniesData {
//                                    ForEach(topicData.word.indices, id: \.self) { index in
//                                        WordView(
//                                            word: topicData.word[index],
//                                            user: topicData.user[index]
//                                        )
//                                    }
//                                }
//                            case "Miracles":
//                                if let topicData = topicsViewModel.miraclesData {
//                                    ForEach(topicData.word.indices, id: \.self) { index in
//                                        WordView(
//                                            word: topicData.word[index],
//                                            user: topicData.user[index]
//                                        )
//                                    }
//                                }
//                            case "Correcting False Teachings":
//                                if let topicData = topicsViewModel.correctingFalseTeachingsData {
//                                    ForEach(topicData.word.indices, id: \.self) { index in
//                                        WordView(
//                                            word: topicData.word[index],
//                                            user: topicData.user[index]
//                                        )
//                                    }
//                                }
//                            default:
//                                EmptyView()
//                            }
//                        }
//                    }
//                }

            }
            .padding(.top, 40)
        }
        .background(Color.black)
        .onAppear {
            if viewRouter.topic == "Jesus" && topicsViewModel.jesusData == nil ||
               viewRouter.topic == "Torah" && topicsViewModel.torahData == nil ||
               viewRouter.topic == "Prophecies" && topicsViewModel.propheciesData == nil ||
               viewRouter.topic == "Scripture" && topicsViewModel.scriptureData == nil ||
               viewRouter.topic == "Gospels" && topicsViewModel.gospelsData == nil ||
               viewRouter.topic == "Revelation" && topicsViewModel.revelationData == nil ||
               viewRouter.topic == "End of Days" && topicsViewModel.endOfDaysData == nil ||
               viewRouter.topic == "Testimonies" && topicsViewModel.testimoniesData == nil ||
               viewRouter.topic == "Miracles" && topicsViewModel.miraclesData == nil ||
               viewRouter.topic == "Correcting False Teachings" && topicsViewModel.correctingFalseTeachingsData == nil {
                print("topicsViewModel.jesusData:",topicsViewModel.jesusData as Any)

                fetchTopicData(topic: viewRouter.topic) { result in
                    switch result {
                    case .success(let result):
                        DispatchQueue.main.async {
                            switch viewRouter.topic {
                            case "Jesus":
                                topicsViewModel.jesusData = result
                            case "Torah":
                                topicsViewModel.torahData = result
                            case "Prophecies":
                                topicsViewModel.propheciesData = result
                            case "Scripture":
                                topicsViewModel.scriptureData = result
                            case "Gospels":
                                topicsViewModel.gospelsData = result
                            case "Revelation":
                                topicsViewModel.revelationData = result
                            case "End of Days":
                                topicsViewModel.endOfDaysData = result
                            case "Testimonies":
                                topicsViewModel.testimoniesData = result
                            case "Miracles":
                                topicsViewModel.miraclesData = result
                            case "Correcting False Teachings":
                                topicsViewModel.correctingFalseTeachingsData = result
                            default:
                                break
                            }
                        }
                    case .failure(_):
                        DispatchQueue.main.async {
                            noData = true
                        }
                    }
                }
            }
        }
    }
}

func fetchTopicData(topic: String, completion: @escaping (Result<TopicData, Error>) -> Void) {
    guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
          let serverIpUrl = URL(string: serverIpUrlString) else {
        print("serverIpUrlString is not set or invalid")
        return
    }

    let topicDataEndpoint = "/api/topicData"
    
    let fullURL = serverIpUrl.appendingPathComponent(topicDataEndpoint)
    print("Full URL:", fullURL)
    
    var request = URLRequest(url: fullURL)
    request.httpMethod = "POST"
    
    let requestBody = ["topic": topic]

    if let data = try? JSONSerialization.data(withJSONObject: requestBody) {
        request.httpBody = data
    } else {
        print("Failed to encode searchTerm to JSON data.")
        completion(.failure(NSError(domain: "", code: 0, userInfo: nil)))

        return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error)")
            return
        }

        guard let data = data else {
            print("No data received")
            return
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            print("jsonString:", jsonString)
        } else {
            print("Failed to convert data to string.")
        }

        do {
              let decoder = JSONDecoder()
              let topicData = try decoder.decode(TopicData.self, from: data)
            print("topicData:", topicData)
              completion(.success(topicData))
          } catch {
              print("Error decoding JSON:", error)
              completion(.failure(error))
          }
    }.resume()

}
//
//struct TopicView_Previews: PreviewProvider {
//    static var previews: some View {
//        let previewWord = Word(content: "Jesus is the way, the truth, and the life. No one can get to The Father except through him.")
//        let previewUser = IUser(name: "John Doe") // Replace with an appropriate initializer for IUser
//        let previewVideo = Video(url: "https://example.com/video", title: "Example Video") // Replace with an appropriate initializer for Video
//
//        let topicData = TopicData(
//            video: [previewVideo],
//            word: [previewWord],
//            user: [previewUser]
//        )
//
//        return TopicView(topic: "Jesus", topicData: topicData)
//    }
//}

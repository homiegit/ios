import SwiftUI

struct PreviewView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @EnvironmentObject var viewModel: ContentViewModel

    @State private var videoAsset: VideoAsset?
    @State private var uploadedAsset: UploadedAsset?

    
    //var url: URL
    @State var isPlaying = true
    @State var isMuted = false
    
    @Binding private var caption: String?
    @Binding private var urlSources: [UserUrlSource]?
    @Binding private var bibleSources: [UserBibleSource]?

    @Binding private var selectedTopics: [String]?
    
    @State private var transcriptionResults: String? = ""
    @State private var cues: [Items]? = []
    
    @State private var transcription: String? = ""
    @State private var onlyWordsTranscription: [String]? = []
    @State private var createdAt: String = ""


    
    @State private var isPostVideoInProgress: Bool = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding private var secondsWatched: Int
    public init(caption: Binding<String?> = .constant(nil), urlSources: Binding<[UserUrlSource]?> = .constant(nil), bibleSources: Binding<[UserBibleSource]?> = .constant(nil),
                selectedTopics: Binding<[String]?> = .constant(nil),
                secondsWatched: Binding<Int> = .constant(0)) {
        self._caption = caption
        self._urlSources = urlSources
        self._bibleSources = bibleSources
        self._selectedTopics = selectedTopics
        self._secondsWatched = secondsWatched
    }
    
    var body: some View {
            VStack {
                SingleVideoView(
                    //url: viewRouter.concatenatedURL,
                    isPlaying: $isPlaying,
                    isMuted: $isPlaying,
                    secondsWatched: $secondsWatched
                    
                )
                .frame(height: UIScreen.main.bounds.height / 1.2)
                .overlay(
                    VStack {
                        Spacer()
                        HStack{
                            Spacer()
                            Button(action: {
                                viewRouter.popToContentView()
                                
                                uploadVideo()
                            }) {
                                Text("Upload")
                                    .font(.system(size: 24))
                                    .padding(10)
                                    .foregroundColor(Color.white)
                                    .background(Color.black)
                                    .border(Color.white, width: 1)
                            }
                            //.highPriorityGesture(TapGesture())
                            .disabled(isPostVideoInProgress) // Disable the button while posting in progress
                            .opacity(isPostVideoInProgress ? 0.5 : 1.0) // Adjust opacity while posting in progress
                        }
                    }
                )
//                .alert(isPresented: $isVideoSaved) {
//                    Alert(title: Text("Your video has been posted!"), message: nil, dismissButton: .default(Text("OK"), action: {
//                        presentationMode.wrappedValue.dismiss()
//                    }))
//                }
            }
//            .onAppear {
//                // This block will execute when isVideoSaved changes from false to true
//                if isVideoSaved {
//                    presentationMode.wrappedValue.dismiss()
//                }
//            }
            .background(Color.black)
        
    }
    
    
    private func uploadVideo(withRetryCount retryCount: Int = 3) {
        isPostVideoInProgress = true
        
        guard let concatenatedURL = viewRouter.concatenatedURL else {
            print("Error: Invalid concatenated URL")
            isPostVideoInProgress = false
            return
        }
        var request = URLRequest(url: concatenatedURL)
        request.timeoutInterval = 600 // Set the timeout interval to 10 minutes

        
        let maxRetryCount = retryCount
        var currentRetry = 0

        func performUpload() {
            
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    if let nsError = error as NSError?, nsError.code == NSURLErrorTimedOut && currentRetry < maxRetryCount {
                        // Retry the request
                        currentRetry += 1
                        print("Retrying request (attempt \(currentRetry) of \(maxRetryCount))...")
                        performUpload() // Recursively retry the request
                    } else {
                        print("Error fetching video data: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            isPostVideoInProgress = false
                        }
                    }
                    return
                }
                
                guard let videoData = data else {
                    print("Error: No video data")
                    DispatchQueue.main.async {
                        isPostVideoInProgress = false
                    }
                    return
                }
                
                let fileName = concatenatedURL.lastPathComponent
                //let fileExtension = concatenatedURL.pathExtension
                
                handleVideo(videoData: videoData, fileName: fileName) { result in
                    switch result {
                    case .success(let responseObj):
                        print("Video uploaded to Sanity and transcribed", responseObj)
                        let videoAssetData = Asset(_type: "reference", _ref: responseObj.sanityAsset._id)
                        self.videoAsset = VideoAsset(asset: videoAssetData, videoUrl: URL(string: responseObj.sanityAsset.url)!)
                        //                    self.uploadedAsset = UploadedAsset(url: uploadedAsset.url, extension: uploadedAsset.extension, originalFilename: uploadedAsset.originalFilename)
                        self.transcription = responseObj.transcriptionObject.transcript
                        self.transcriptionResults = responseObj.transcriptionObject.transcriptionResults
                        self.cues = responseObj.transcriptionObject.cues
                        
                        if let transcription = transcription {
                            convertToWords(value: transcription) {result in
                                switch result {
                                case .success(let onlyWords):
                                    onlyWordsTranscription = onlyWords
                                    
                                    postVideo {result in
                                        switch result {
                                        case .success(_):
                                            DispatchQueue.main.async {
                                                viewRouter.concatenatedURL = URL(string: "")
                                                viewRouter.recordedURLs = []
                                                viewRouter.caption = ""
                                                viewRouter.urlSources = []
                                                viewRouter.bibleSources = []
                                                viewRouter.selectedTopics = []
                                                
                                                viewRouter.isVideoSaved = true
                                            }
                                        case .failure(let error):
                                            print("Error posting video", error)
                                        }
                                    }
                                case .failure(let error):
                                    print("Error getting onlyWordstranscription", error)
                                }
                            }
                            
                        } else {
                            print("no transcription")
                        }
                        
                        
                    case .failure(let error):
                        print("Error uploading video asset:", error.localizedDescription)
                        DispatchQueue.main.async {
                            isPostVideoInProgress = false
                        }
                    }
                }
                
            }
            
            task.resume()
        }
        performUpload()
    }

    struct ResponseObject: Codable {
        var sanityAsset: SanityAssetDocument
        var transcriptionObject: TranscriptionResponse
    }
    
    struct TranscriptionResponse: Codable {
        let transcriptionResults: String?
        let cues: [Items]
        let transcript: String?
    }

    private func handleVideo(videoData: Data, fileName: String, completion: @escaping (Result<ResponseObject, Error>) -> Void) {
        guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
              let uploadVideoAssetToSanityEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/handleVideo") else {
            print("Error: Invalid server URL or endpoint")
            return
        }
        
        print(uploadVideoAssetToSanityEndpoint)
        print("videoData:", videoData)
        
        // Create a boundary for the multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        
        let maxRetryCount = 3
        var currentRetry = 0
        var request = URLRequest(url: uploadVideoAssetToSanityEndpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 600
        
        // Set the Content-Type to multipart/form-data with the specified boundary
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // Create the multipart form data body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"videoData\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/\((fileName as NSString).pathExtension)\r\n\r\n".data(using: .utf8)!)
        body.append(videoData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        func performHandleVideo() {
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    if let nsError = error as NSError?, nsError.code == NSURLErrorTimedOut && currentRetry < maxRetryCount {
                        // Retry the request
                        currentRetry += 1
                        print("Retrying request (attempt \(currentRetry) of \(maxRetryCount))...")
                        performHandleVideo() // Recursively retry the entire process
                    } else {
                        print("Error: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    do {
                        if let responseData = data {
                            // Print the received JSON data for debugging
                            print("Received JSON data: \(String(data: responseData, encoding: .utf8) ?? "")")
                            
                            let responseObj = try JSONDecoder().decode(ResponseObject.self, from: responseData)
                            completion(.success(responseObj))
                        } else {
                            print("Error: No data received")
                            completion(.failure(NSError(domain: "DataErrorDomain", code: -1, userInfo: nil)))
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
                        completion(.failure(error))
                    }
                } else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    let error = NSError(domain: "HTTPErrorDomain", code: statusCode, userInfo: nil)
                    print("Error: Invalid response or HTTP status code")
                    completion(.failure(error))
                }
            }
            
            
            task.resume()
            
        }
        
        performHandleVideo()
    }
    
    func convertToWords(value: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let cleanedText = value.replacingOccurrences(of: "[^\\w\\s\"']", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let onlyWords = cleanedText.split(separator: " ").map { String($0) }
        
        // Unwrap the optional onlyWordsTranscription
//        if let unwrappedWordsTranscription = onlyWordsTranscription {
            //onlyWordsTranscription = words
        print("onlyWords:", onlyWords)
            
            // Call the completion handler with the result
            completion(.success(onlyWords))
//        } else {
//            print("Error: onlyWordsTranscription is nil")
//            // Call the completion handler with a failure result
//            let error = NSError(domain: "Conversion Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "onlyWordsTranscription is nil"])
//            completion(.failure(error))
//        }
    }
    
    private func getCurrentTime() -> String {
        let pacificTimeOptions: DateFormatter = {
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            formatter.dateFormat = "MMM d, yyyy, h:mm a"
            return formatter
        }()
        
        let currentTime = Date()
        let formattedTime = pacificTimeOptions.string(from: currentTime)
        
        return formattedTime
    }
    
    private func postVideo(completion: @escaping (Result<Void, Error>) -> Void) {
        print("posting video")
        let currentTime = getCurrentTime()
        createdAt = currentTime
        print("createdAt:", createdAt)
        print("videAsset:", videoAsset as Any)
        if !createdAt.isEmpty {
            let id = newUUID.uuidString
            let videoAssetUrl = videoAsset?.videoUrl
            let video = Video(
                _type: "video",
                isVideoReliable: Video.IsVideoReliable(reliability: "pending", proof: Proof(text: "", sources: [], flag: "existing")),
                isFeatured: false,
                videoUrl: videoAssetUrl!,
                caption: viewRouter.caption,
                urlSources: viewRouter.urlSources,
                bibleSources: viewRouter.bibleSources,
                selectedTopics: viewRouter.selectedTopics,
                typeOfContent: [""],
                transcriptionResults: transcriptionResults,
                cues: cues,
                transcription: transcription,
                onlyWordsTranscription: onlyWordsTranscription,
                godKeywords: [],
                translatedText: nil,
                claims: nil,
                videoId: id,
                createdAt: createdAt,
                timeAgo: nil,
                video: videoAsset!,
                _id: id,
                postedBy: PostedBy(_ref: UserDefaults.userProfile!._id),
                likes: [],
                dislikes: [],
                comments: [],
                views: [],
                averageSecondsWatched: 0
            )
            print("video:", video)
            
            guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
                  let createVideoEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/createVideo") else {
                print("Error: Invalid server URL or endpoint")
                return
            }
            
            var request = URLRequest(url: createVideoEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                 let jsonData = try JSONEncoder().encode(video)
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
                         completion(.failure(error))
                         return
                     }
                     
                     if let httpResponse = response as? HTTPURLResponse {
                         if (200...299).contains(httpResponse.statusCode) {
                             print("Video saved")
                             completion(.success(()))
                             
                         } else {
                             print("Error: HTTP status code \(httpResponse.statusCode)")
                             completion(.failure(NSError(domain: "HTTP status code \(httpResponse.statusCode)", code: 0, userInfo: nil)))
                         }
                     }
                 }.resume()
             } catch {
                 print("Error: Failed to serialize JSON - \(error.localizedDescription)")
                 completion(.failure(error))
             }
        } else {
            print("No videoAsset:", videoAsset as Any)
            completion(.failure(NSError(domain: "No videoAsset", code: 0, userInfo: nil)))
        }
    }
    
//    struct PreviewView_Previews: PreviewProvider {
//        static var previews: some View {
//            let url = URL(string: "https://example.com/video.mp4")!
//            return PreviewView(url: url)
//        }
//    }
}

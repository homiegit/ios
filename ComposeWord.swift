import SwiftUI

struct CheckBox: View {
    @Binding var isChecked: Bool
    var checkToggle: () -> Void

    var body: some View {
        Button(action: {
            isChecked.toggle()
            checkToggle()
        }) {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(isChecked ? Color.blue : Color.gray)
        }
    }
}

struct ComposeWord: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @State private var isWordReliable: (reliability: String, proof: [String]) = (reliability: "pending", proof: [])
    @State private var isUserReliable: (reliability: String, proof: [String]) = (reliability: "pending", proof: [])
    @State private var showTopics = false
    @State private var text = ""
    
    @State private var sourceUrl: String = ""
    @State private var title: String = ""
    @State private var invalidLink: String?
    @State private var showInvalidLinkAlert: Bool = false

    @State private var sources: [UserSources] = [] {
        didSet {
            print("sources set to:", sources as Any)
        }
    }
    //@State private var urls: [String] = []
    @State private var onlyWords: [String] = []
    @State private var selectedTopics: [String] = []
    @State private var selectedAnswers: [String] = []
    @State private var createdAt = ""
    @State private var savingPost = false
    @State private var isWordSaved = false

    

    var body: some View {
        VStack {
            VStack {
                Text("We encourage you to spread truth about Lord")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
                
                //                HStack {
                //                    Spacer()
                //                    NavigationLink(destination: Guidelines()) {
                //                        Text("guidelines")
                //                            .foregroundColor(.blue)
                //                            .font(.system(size: 14))
                //                            .multilineTextAlignment(.center)
                //                            .padding(.vertical)
                //                    }
                //                    Spacer()
                //                }
                //
                //                Text("to understand what will be permitted")
                //                    .foregroundColor(.white)
                //                    .font(.system(size: 14))
                //                    .multilineTextAlignment(.center)
                //                    .padding(.vertical)
                
                HStack {
                    TextField("Paste URL", text: $sourceUrl)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .frame(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.height / 15)
                    
                    Spacer()
                    TextField("Title", text: $title)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .frame(width: UIScreen.main.bounds.width / 4, height: UIScreen.main.bounds.height / 10)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        addUrl()
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                    .padding(.leading, 8)
                }
                VStack {
                    if let invalidText = invalidLink, !invalidText.isEmpty {
                        Text("\(invalidText) is invalid")
                            .font(.system(size: 12))
                            .foregroundColor(Color.red)
                    }
                

                    
                    ForEach(sources, id: \.self) { source in
                        HStack {
                            Button(action: {
                                testLink(source.url) { result in
                                    switch result {
                                        case .success(let isValid):
                                            if isValid {
                                                if let url = URL(string: source.url) {
                                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                                }
                                            } else {
                                                showInvalidLinkAlert = true
                                            }
                                        case .failure(let error):
                                            // Handle the error if needed
                                            print("Error: \(error)")
                                        }
                                }
                            }) {
                                Text(source.url)
                                    .foregroundColor(Color.blue)
                                    .font(.system(size: 12))
                            }

                             Button(action: {
                                 removeUrl(deletedSource: source)
                             }) {
                                 Image(systemName: "delete.left")
                                     .foregroundColor(.red)
                             }
                         }
                    }
                
                }
            }
//                List(urls, id: \.self) { url in
//                    HStack {
//                        //Text(url)
//                        Spacer()
//                        Button(url) {
//                            testLink(url)
//                        }
//                    }
//                }
                .padding()
                TextEditor(text: $text)
                    .foregroundColor(.white)
                    .frame(minHeight: 150)
                    .padding()
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .border(Color.gray, width: 2)
                    .toolbar {
                                        ToolbarItem(placement: .keyboard, content: {
                                            Button("Hide Keyboard") {
                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            }
                                        })
                                    }


            Button(action: { showTopics.toggle() }) {
                Text("Choose a Topic")
                    .foregroundColor(.white)
            }

            if showTopics {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(topics, id: \.name) { item in
                            HStack {
                                CheckBox(
                                    isChecked: Binding(
                                        get: { selectedTopics.contains(item.name.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)) },
                                        set: { isChecked in
                                            handleTopicChange(value: item.name, checked: isChecked)
                                        }
                                    ),
                                    checkToggle: {} // Empty closure as it's not needed
                                )

                                Text(item.name)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                    .padding(.leading, 8)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }

            Button(action: {
                spreadTruth()
                viewRouter.popToContentView()
            }) {
                Text("Spread Truth")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
            
            }
                
            
            Spacer()
        }
        .background(Color.black)
        .padding()
        .onAppear {
            print("userProfile._ref:", UserDefaults.userProfile!)
        }

    }
    
    private func addUrl() {
        print("current sources:", sources as Any)
        
        testLink(sourceUrl) { result in
            switch result {
                case .success(let validLink):
                    if validLink {
                        let newSource = UserSources(url: sourceUrl, title: title, _key: UUID().uuidString)
                        
                        if sources.isEmpty {
                            sources = [newSource]
                        } else {
                            sources.append(newSource)
                        }
                        
                        sourceUrl = ""
                        title = ""
                        invalidLink = nil
                    } else {
                        invalidLink = sourceUrl
                        showInvalidLinkAlert = true
                    }
                case .failure:
                    break // Handle failure case if needed
            }
        }
    }

    
    private func removeUrl(deletedSource: UserSources) {
        if let index = sources.firstIndex(of: deletedSource) {
            sources.remove(at: index)
            
            // Remove the URL from invalidLinks if it exists
//            if let invalidIndex = invalidLinks.firstIndex(of: deletedSource.url) {
//                invalidLinks.remove(at: invalidIndex)
//            }
        }
    }


    private func testLink(_ urlString: String?, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            completion(.success(false)) // URL is invalid
            return
        }
        
        // Check if the URL can be opened (valid link)
        if UIApplication.shared.canOpenURL(url) {
            completion(.success(true))
        } else {
            completion(.success(false))
        }
    }

    
    private func handleTopicChange(value: String, checked: Bool) {
        print("value:", value)
        print("checked:", checked)
        let topicWithoutSpaces = value.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        
        if checked {
            if selectedTopics.count == 0 {
                selectedTopics = [topicWithoutSpaces]
            } else {
                selectedTopics.append(topicWithoutSpaces)
            }
        } else {
            selectedTopics.removeAll { $0 == topicWithoutSpaces }
        }
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


    private func convertToWords(value: String) {
        let cleanedText = value.replacingOccurrences(of: "[^\\w\\s\"']", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let words = cleanedText.split(separator: " ").map { String($0) }

        onlyWords = words
        print("onlyWords:", onlyWords)
    }

    private func handleWord(value: String) {
        text = value
        print("text updated to:", value)
    }

    private func matchingTruth() {
        //run text through model

        if !text.isEmpty {
            isWordReliable = (reliability: "true", proof: [""])
        }
    }

    private func spreadTruth() {
        let currentTime = getCurrentTime()
        createdAt = currentTime
        convertToWords(value: text)

        if !text.isEmpty && !createdAt.isEmpty && !onlyWords.isEmpty {
            let word: [String: Any] = [
                "_type": "word",
                "text": text,
                "userSources": sources,
                "onlyWords": onlyWords,
                "isWordReliable": [
                    "reliability": isWordReliable.reliability,
                ],
                "selectedTopics": selectedTopics,
                "typeOfContent": [""],
                "createdAt": createdAt,
                "postedBy": [
                    "_type": "postedBy",
                    "_ref": UserDefaults.userProfile!._id,
                ]
            ]
            print("word:", word)

            guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
                  let createWordEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/createWord") else {
                print("Error: Invalid server URL or endpoint")
                return
            }

            var request = URLRequest(url: createWordEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: word)
                request.httpBody = jsonData

                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                        return
                    }

                    if let httpResponse = response as? HTTPURLResponse {
                        if (200...299).contains(httpResponse.statusCode) {
                            print("Word saved")
                            isWordSaved = true
                        } else {
                            print("Error: HTTP status code \(httpResponse.statusCode)")
                        }
                    }
                }.resume()
            } catch {
                print("Error: Failed to serialize JSON - \(error.localizedDescription)")
            }
        } else {
            print("No onlyWords")
        }
    }

}

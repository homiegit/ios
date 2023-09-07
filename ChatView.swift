import SwiftUI
import WebKit

struct Message: Codable, Hashable {
    var message: String
    var createdAt: Date
    var type: String
}

struct ChatView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @State var responses: [Message] = [Message(message: "Ask me anything about the Book of Genesis", createdAt: Date(), type: "response")]
    @State var userMessages: [Message] = []
    @State var message: String = ""

    var combinedMessages: [Message] {
        return (responses + userMessages).sorted(by: { $0.createdAt < $1.createdAt })
    }

    var body: some View {
        VStack {
            HStack {
                Text("Ask the Homie")
                    .foregroundColor(.blue)
                    .font(.system(size: 30).bold())
            }
            ScrollViewReader { scrollViewProxy in
                ScrollView(.vertical) {
                    Spacer(minLength: UIScreen.main.bounds.height / 1.45)

                    VStack {
                        ForEach(combinedMessages, id: \.self) { message in
                            HStack {
                                if message.type == "userMessage" {
                                    Spacer()
                                }
                                Text(message.message)
                                    .foregroundColor(message.type == "response" ? .white : .white)
                                    .padding(.horizontal, 10)
                                    .background(message.type == "response" ? Color.blue : Color.clear)
                                    .border(message.type == "userMessage" ? Color.white : Color.clear, width: 1)
                                    .cornerRadius(message.type == "response" ? 8: 0)
                                    .frame(maxWidth: UIScreen.main.bounds.width / 1.4, alignment: message.type == "response" ? .leading : .trailing)
                                if message.type == "response" {
                                    
                                    Spacer()
                                }
                            }
                            .padding(.bottom, 5)
                        }
                    }
                    .id("ChatScrollView")
                    //.border(Color.white, width: 2)
                    .padding(.bottom, 10)
                }
                .onChange(of: combinedMessages.count) { _ in
                    //print("1")
                    withAnimation {
                        scrollViewProxy.scrollTo("ChatScrollView", anchor: .bottom)
                    }
                }
                .frame(
                    width: UIScreen.main.bounds.width / 1.05,
                    height: UIScreen.main.bounds.height / 1.3
                )
 
                //.border(Color.white, width: 2)
                HStack {
                    TextField("", text: $message)
                        .border(Color.white, width: 1)
                        .font(.system(size: 20))
                        .foregroundColor(.white)

                    Button(action: {
                        sendMessageToApi { result in
                            responses.append(Message(message: result, createdAt: Date(), type: "response"))
                        }
                    }) {
                        Image(systemName: "arrow.up.message")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }
        }
        .background(Color.black)

    }
    
    func sendMessageToApi(completion: @escaping (String) -> Void) {
        userMessages.append(Message(message: message, createdAt: Date(), type: "userMessage"))

        guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
              let voiceFlowEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/voiceFlow") else {
            print("Error: Invalid server URL or endpoint")
            return
        }

        var requestData: [String: Any] = [
            "body": [
                "action": [
                    "type": "text",
                    "payload": message
                ]
            ]
        ]
        message = ""
        
        if let userID = UserDefaults.userProfile?._id {
            requestData["userID"] = userID
        }
        
        do {
            let requestData = try JSONSerialization.data(withJSONObject: requestData)
            
            var request = URLRequest(url: voiceFlowEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = requestData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    completion(responseString)
                }
            }.resume()
        } catch {
            print("Error: Failed to create JSON data")
        }
    }
}


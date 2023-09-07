//
//import SwiftUI
//
//
//struct WordView: View {
//    var word: Word
//    var user: IUser
//    
//    @State private var showInfo: Bool = false
//
//    @State private var showSources: Bool = false
//    @State private var showComments: Bool = false
//
//    var body: some View {
//        VStack {
//            HStack {
//                Spacer()
//                UserHeaderView(user: user)
//                    .frame(alignment: .center)
//                    .padding(5)
//                Spacer()
//            }
//            .overlay(
//                HStack {
//                    Spacer()
//                    VStack {
//                        if word.isWordReliable?.reliability != "pending" {
//                            Button(action: {
//                                showInfo.toggle()
//                            }) {
//                                Image(systemName: "info.circle")
//                                    .font(.system(size: 25))
//                                    .foregroundColor(borderColor())
//                                    .padding(3)
//                            }
//                        }
//                        
//                        Button(action: {
//                            showComments.toggle()
//                            
//                        }) {
//                            Image(systemName: showComments ? "bubble.right.fill" : "bubble.right")
//                                .font(.system(size: 30))
//                                .foregroundColor(.white)
//                        }
//                    }
//                    .padding(.top, 35)
//                }
//            )
//
//            if showInfo {
//                HStack {
//                    Text(word.isWordReliable?.proof?[0].text ?? "")
//                        .foregroundColor(.black)
//                }
//                .background(borderColor())
//
//                VStack {
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            showSources.toggle()
//                            
//                        }) {
//                            Text("Show Sources")
//                                .foregroundColor(.black)
//                        }
//                        Spacer()
//                    }
//                    if showSources {
//                        if let proofSources = word.isWordReliable?.proof?[0].sources {
//                            let urls = proofSources.compactMap { $0.url }
//                            ForEach(urls, id: \.self) { url in
//                                Link(destination: URL(string: url) ?? URL(string: "")!) {
//                                    Text(url)
//                                        .foregroundColor(.white)
//                                }
//                            }
//                        }
//                    }
//
//                }
//                .background(borderColor())
//
//            }
//            Text(word.text)
//                .font(.subheadline)
//                .foregroundColor(.white)
//                .frame(width: UIScreen.main.bounds.width - 40, height: UIScreen.main.bounds.height * 0.05)
//            if showComments {
//                CommentsView(word: word)
//                    .padding(.bottom, 5)
//
//            }
//        }
//        .border(borderColor(), width: 2)
//        .background(Color.black)
//        .onAppear {
//            print("word received:", word)
//            print("user received:", user)
//        }
//    }
//    
//    func fetchComments(_ref: String) {
//        
//    }
//    
//    func borderColor() -> Color {
//        switch word.isWordReliable?.reliability {
//        case "false":
//            return .red
//        case "inaccurate":
//            return .yellow
//        case "true":
//            return .blue
//        default:
//            return .white
//        }
//    }
//}

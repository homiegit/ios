import SwiftUI

struct UserHeaderView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var viewRouter: ViewRouter
    var video: Video
    @Binding var showInfo: Bool
    var borderColor: Color
    @Binding var showUserSources: Bool
    @Binding var showActions: Bool
    var actions: [String] = ["download", "suggest a review", "report", ]
    
    var user: IUser
    
    init(video: Video, showInfo: Binding<Bool>, borderColor: Color, showUserSources: Binding<Bool>, showActions: Binding<Bool>, user: IUser) {
        self.video = video
        self._showInfo = showInfo
        self.borderColor = borderColor
        self._showUserSources = showUserSources
        self._showActions = showActions
        self.user = user
      }

    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                DispatchQueue.main.async{
                    viewModel.singleProfileRef = user._id
                    if viewRouter.path.contains("SearchView") {
                        viewRouter.popToView("ProfileView", atIndex: viewRouter.path.count)
                    }
                    viewRouter.popToView("ProfileView", atIndex: viewRouter.path.count)
                }
            }) {
                Text(user.userName)
                    .font(.system(size: 18).bold())
                    .padding(3)
                    .foregroundColor(foregroundUserColor(for: user))
                    .background(backgroundUserColor(for: user))
                    .border(Color.white, width: user.isUserReliable?.reliability == "pending" ? 1 : 0)
                
            }
            Spacer()
        }
        .accessibilityIdentifier("Identifier")
        .background(Color.clear)
        .overlay(
            VStack {
                HStack {
                    Button(action: {
                        if showInfo {
                            showInfo.toggle()
                        }
                        if showUserSources {
                            showUserSources.toggle()
                        }
                        showActions.toggle()

                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Color.black)
                            .padding(5)
                            .rotationEffect(showActions ? .degrees(0) : .degrees(90))
                    }
                    Spacer(minLength: (UIScreen.main.bounds.width / 2) - CGFloat(user.userName.count))
                    //Spacer(minLength: CGFloat(user.userName.count) / 4)
                    if (video.urlSources?.count != 0 || video.bibleSources?.count != 0) && (video.urlSources?.count != nil || video.bibleSources?.count != nil) {
                        Spacer(minLength: 0)
                        Button(action:{
                            if showInfo {
                                showInfo.toggle()
                            }
                            if showActions {
                                showActions.toggle()
                            }
                            showUserSources.toggle()
                        }) {
                            Image(systemName: "filemenu.and.cursorarrow")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                        
                    }
                    Spacer()
                    VStack {
                        if video.isVideoReliable.reliability != "pending" {
                                Button(action: {
                                    if showActions {
                                        showActions.toggle()
                                    }
                                    if showUserSources {
                                        showUserSources.toggle()
                                    }
                                    showInfo.toggle()
                                }) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 25))
                                        .foregroundColor(borderColor)
                                        .padding(5)
                                }
                            }
                            
                        
                    }
                }
                .padding(.leading, 10)
            }
        )
//        .overlay(
//            HStack {
//
//
//                Spacer()
//            }
//        )
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
}

func backgroundUserColor(for user: IUser) -> Color {
    let reliability = user.isUserReliable?.reliability

    switch reliability {
    case "false":
        return .red
    case "inaccurate":
        return .yellow
    case "true":
        return .green
    case "pending":
        return .clear
    default:
        return .gray
    }
}

func foregroundUserColor(for user: IUser) -> Color {
    let reliability = user.isUserReliable?.reliability

    switch reliability {
    case "false":
        return .black
    case "inaccurate":
        return .black
    case "true":
        return .black
    case "pending":
        return .white
    default:
        return .blue
    }
}

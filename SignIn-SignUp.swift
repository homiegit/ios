import SwiftUI

struct UserSignUpData: Codable {
    var signUpUserName: String
    var signUpEmail: String
    var signUpPassword: String
    var signUpPhoneNumber: String
}

struct UserSignInData: Codable {
    var signInUserName: String?
    var signInEmail: String?
    var signInPassword: String
}
let service = "www.homie-media.com"

struct CSRFData: Codable {
    var csrfSecret: String
    var csrfToken: String
}

struct AstraUserData: Codable {
    var _id: String
    var username: String
}

extension UserDefaults {
    // Define a computed property to access the userProfile globally
    static var userProfile: AstraUserData? {
        get {
            if let data = UserDefaults.standard.data(forKey: "userProfile"),
               let userProfile = try? JSONDecoder().decode(AstraUserData.self, from: data) {
                return userProfile
            }
            return nil
        }
        set {
            if let newValue = newValue,
               let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "userProfile")
            } else {
                UserDefaults.standard.removeObject(forKey: "userProfile")
            }
        }
    }
    
    static var image: IUser.Image? {
        get {
            if let data = UserDefaults.standard.data(forKey: "image"),
               let image = try? JSONDecoder().decode(IUser.Image.self, from : data) {
                return image
            }
            return nil
        }
        set {
            if let newValue = newValue,
               let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "image")
            } else {
                UserDefaults.standard.removeObject(forKey: "image")
            }
        }
    }
}

struct SignInView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var signInUserName: String = ""
    @State private var signInEmail: String = ""
    @State private var signInPhoneNumber: String = ""
    @State private var signInPassword: String = ""
    
    @State private var signUpUserName: String = ""
    @State private var signUpEmail: String = ""
    @State private var signUpPhoneNumber: String = ""
    @State private var signUpPassword: String = ""
    
    @State private var showingSignIn: Bool = true
    @State private var showingSignUp: Bool = false
    @State private var signInWithUserName: Bool = true
    @State private var signInWithEmail: Bool = false
    @State private var signInWithPhoneNumber: Bool = false
    
    @State private var hidePassword: Bool = true
    @State private var wrongPassword: Bool = false
    @State private var createdCSRFData: Bool = false
    
    @State private var locked: Bool = true
    @State var isLoggedIn: Bool = false
    
    var body: some View {
        //NavigationStack {
            ZStack(alignment: .topTrailing) {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 15) {
                    HStack {
                        Text("Sign In")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding()
                            .underline(showingSignIn ? true : false, color: .blue)
                            .onTapGesture {
                                self.showingSignUp = false
                                self.showingSignIn = true
                            }
                        
                        Text("Sign Up")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding()
                            .underline(showingSignUp ? true : false, color: .blue)
                            .onTapGesture {
                                self.showingSignIn = false
                                self.showingSignUp = true
                            }
                    }
                    .frame(maxWidth: .infinity)
                    
                    HStack {
                        Text("User Name")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .underline(signInWithUserName ? true : false, color: .blue)
                            .onTapGesture {
                                self.signInWithEmail = false
                                self.signInWithPhoneNumber = false
                                self.signInWithUserName = true
                            }
                        
                        Text("Email")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .underline(signInWithEmail ? true : false, color: .blue)
                            .onTapGesture {
                                self.signInWithUserName = false
                                self.signInWithPhoneNumber = false
                                self.signInWithEmail = true
                            }
                        
                    }
                    .frame(maxWidth: .infinity)
                    
                    
                    if showingSignIn {
                        VStack(spacing: 15) {
                            if signInWithUserName {
                                ZStack {
                                    if signInUserName.isEmpty {
                                        Text("User Name")
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .offset(y: 0)
                                    }
                                    
                                    TextField("", text: $signInUserName)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.gray.opacity(0.5))
                                        .cornerRadius(8)
                                }
                                ZStack{
                                    if signInPassword.isEmpty {
                                        Text("Password")
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .offset(y: 0)
                                    }
                                    if hidePassword {
                                        SecureField("", text: $signInPassword)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.gray.opacity(0.5))
                                            .cornerRadius(8)
                                            .overlay{
                                                HStack{
                                                    Spacer()
                                                    Button(action: {
                                                        hidePassword = false
                                                    }) {
                                                        Image(systemName: "eye.slash.circle.fill")
                                                            .font(.system(size: 30))
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                                .padding(5)
                                            }
                                    } else {
                                        
                                        TextField("", text: $signInPassword)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.gray.opacity(0.5))
                                            .cornerRadius(8)
                                            .overlay{
                                                HStack{
                                                    Spacer()
                                                    Button(action: {
                                                        hidePassword = true
                                                    }) {
                                                        Image(systemName: "eye.circle.fill")
                                                            .font(.system(size: 30))
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                                .padding(5)
                                            }
                                    }
                                }
                            }
                            if signInWithEmail {
                                ZStack(alignment: .leading) {
                                    if signInEmail.isEmpty {
                                        Text("Email")
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .offset(y: 0)
                                    }
                                    
                                    TextField("", text: $signInEmail)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.gray.opacity(0.5))
                                        .cornerRadius(8)
                                }
                                ZStack{
                                    if signInPassword.isEmpty {
                                        Text("Password")
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .offset(y: 0)
                                    }
                                    if hidePassword {
                                        SecureField("", text: $signInPassword)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.gray.opacity(0.5))
                                            .cornerRadius(8)
                                            .overlay{
                                                HStack{
                                                    Spacer()
                                                    Button(action: {
                                                        hidePassword = false
                                                    }) {
                                                        Image(systemName: "eye.slash.circle.fill")
                                                            .font(.system(size: 30))
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                                .padding(5)
                                            }
                                    } else {
                                        
                                        TextField("", text: $signInPassword)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.gray.opacity(0.5))
                                            .cornerRadius(8)
                                            .overlay{
                                                HStack{
                                                    Spacer()
                                                    Button(action: {
                                                        hidePassword = true
                                                    }) {
                                                        Image(systemName: "eye.circle.fill")
                                                            .font(.system(size: 30))
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                                .padding(5)
                                            }
                                    }
                                }
                            }
                            
                            Button(action: {
                                Task {
                                    await handleLogin {result in
                                        switch result {
                                        case .success:
                                            if viewRouter.path.contains("Upload") {
                                                viewRouter.path.removeAll()
                                                viewRouter.popToView("UploadView", atIndex: viewRouter.path.count)
                                            } else {
                                                viewRouter.popToContentView()
                                            }
                                        
                                        case .failure(let error):
                                            print(error)
                                        
                                        }
                                        
                                    }
                                }
                                
                            }) {
                                Text("Sign In")
                                    .foregroundColor(.black)
                                    .frame(width: UIScreen.main.bounds.width / 4)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            
                            // Additional content for the Sign-In view
                            // For example, show a message if the password is incorrect
                            //                        if wrongPassword {
                            //                            Text("Incorrect password")
                            //                                .foregroundColor(.red)
                            //                        }
                            
                            // Add any other views you want to show in the Sign-In view
                            
                        }
                        .padding(.horizontal)
                    }
                    
                    if showingSignUp {
                        // Sign-Up View
                        VStack(spacing: 15) {
                            ZStack{
                                if signUpUserName.isEmpty{
                                    Text("User Name")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .offset(y: 0)
                                }
                                TextField("", text: $signUpUserName)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.gray.opacity(0.5))
                                    .cornerRadius(8)
                            }
                            ZStack{
                                if signUpEmail.isEmpty{
                                    Text("Email")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .offset(y: 0)
                                }
                                TextField("", text: $signUpEmail)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.gray.opacity(0.5))
                                    .cornerRadius(8)
                            }
                            
                            ZStack{
                                if signUpPhoneNumber.isEmpty{
                                    Text("Phone Number")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .offset(y: 0)
                                }
                                TextField("", text: $signUpPhoneNumber)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.gray.opacity(0.5))
                                    .cornerRadius(8)
                            }
                            
                            ZStack{
                                if signUpPassword.isEmpty {
                                    Text("Password")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .offset(y: 0)
                                }
                                if hidePassword {
                                    SecureField("", text: $signUpPassword)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.gray.opacity(0.5))
                                        .cornerRadius(8)
                                        .overlay{
                                            HStack{
                                                Spacer()
                                                Button(action: {
                                                    hidePassword = false
                                                }) {
                                                    Image(systemName: "eye.slash.circle.fill")
                                                        .font(.system(size: 30))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .padding(5)
                                        }
                                } else {
                                    
                                    TextField("", text: $signUpPassword)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.gray.opacity(0.5))
                                        .cornerRadius(8)
                                        .overlay{
                                            HStack{
                                                Spacer()
                                                Button(action: {
                                                    hidePassword = true
                                                }) {
                                                    Image(systemName: "eye.circle.fill")
                                                        .font(.system(size: 30))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .padding(5)
                                        }
                                }
                            }
                            Button(action: {
                                Task {
                                    await createUser()
                                }
                            }) {
                                Text("Sign Up")
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.primary)
                                    .cornerRadius(8)
                            }
                            .disabled(locked)
                            // Add any other views you want to show in the Sign-Up view
                        }
                        .padding(.horizontal)
                    }
                }
                
                .padding(.top, 80)
                .padding(.horizontal)
            }
        
        //}
    }
    
    func fetchCSRFDataAndStore() async throws -> CSRFData? {
        if let serverIPUrl = ProcessInfo.processInfo.environment["serverIpUrl"] {
            // The serverIPUrl is now unwrapped and can be used safely within this scope
            guard let url = URL(string: "\(serverIPUrl)/api/csrfTokenAndSecret") else {
                print("Invalid server URL")
                return nil
            }
            
            // Use the URL and continue with the rest of your code
            
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let csrfData = try JSONDecoder().decode(CSRFData.self, from: data)
                let csrfSecret = csrfData.csrfSecret
                let csrfToken = csrfData.csrfToken
                
                UserDefaults.standard.setValue(csrfToken, forKey: "csrfToken")
                UserDefaults.standard.setValue(csrfSecret, forKey: "csrfSecret")
                
                createdCSRFData = true
                
                print("csrfSecret received from server api/csrfTokenAndSecret:", csrfSecret)
                print("csrfToken received from server api/csrfTokenAndSecret:", csrfToken)
                
                return csrfData
            } catch {
                print("Error fetching CSRF data:", error)
                throw error
            }
        } else {
            print("serverIPUrl is not set in the environment")
            return nil
        }
    }
    
    func createUser() async {
        let userData = UserSignUpData(signUpUserName: signUpUserName, signUpEmail: signUpEmail, signUpPassword: signUpPassword, signUpPhoneNumber: signUpPhoneNumber)
        print("userData:", userData)
        
        do {
            guard let csrfData = try await fetchCSRFDataAndStore() else {
                return
            }
            
            let csrfToken = csrfData.csrfToken
            let csrfSecret = csrfData.csrfSecret
            
            print("csrfSecret from fetchCSRFDataAndStore():", csrfSecret)
            print("csrfToken from fetchCSRFDataAndStore():", csrfToken)
            
            let serverIPUrl = ProcessInfo.processInfo.environment["serverIpUrl"]
            let createUserUrl = URL(string: "\(String(describing: serverIPUrl))/api/astraAndSanity/createUser")!
            
            var request = URLRequest(url: createUserUrl)
            request.httpMethod = "POST"
            request.setValue(csrfToken, forHTTPHeaderField: "x-csrf-Token")
            request.setValue(csrfSecret, forHTTPHeaderField: "x-csrf-Secret")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(userData)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONSerialization.jsonObject(with: data, options: [])
            print("searchRes.data:", response)
            
            if let responseData = response as? [String: Any], let accountFound = responseData["accountFound"] as? Bool {
                if accountFound {
                    print("User already exists. Please sign in")
                } else {
                    print("User created in Astra successfully")
                    // Do something with the user data if needed
                }
            }
        } catch {
            print("Error creating user:", error)
            // Handle error appropriately
        }
    }

    enum LoginError: Error {
        case wrongPassword
        case accountNotFound
        case failedToFetchCSRFData
    }
    
    func handleLogin(completion: @escaping (Result<String, Error>) -> Void) async {
        let userData = UserSignInData(signInUserName: signInUserName, signInEmail: signInEmail, signInPassword: signInPassword)
        print("searching database before logging in")
        
        do {
            if let csrfData = try await fetchCSRFDataAndStore() {
                let csrfToken = csrfData.csrfToken
                let csrfSecret = csrfData.csrfSecret
                
                print("csrfSecret from fetchCSRFDataAndStore():", csrfSecret)
                print("csrfToken from fetchCSRFDataAndStore():", csrfToken)
                
                guard let serverIPUrl = ProcessInfo.processInfo.environment["serverIpUrl"],
                      let searchUserUrl = URL(string: "\(serverIPUrl)/api/astra/searchUser") else {
                    print("Invalid server URL")
                    return
                }
                
                var request = URLRequest(url: searchUserUrl)
                request.httpMethod = "POST"
                request.setValue(csrfToken, forHTTPHeaderField: "x-csrf-Token")
                request.setValue(csrfSecret, forHTTPHeaderField: "x-csrf-Secret")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(userData)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONSerialization.jsonObject(with: data, options: [])
                print("user data from astra:", response)
                
                if let responseData = response as? [String: Any], let user = responseData["user"] as? [String: Any] {
                    print("Account found with matching signUpPassword", user)

                    if let userID = user["id"] as? String {
                        print("User ID found:", userID)
                        UserDefaults.userProfile = AstraUserData(
                            _id: userID,
                            username: user["username"] as! String
                        )
                        getUserDefaultaData(userProfileId: userID) { result in
                            switch result {
                            case .success(let userDefaultsData):
                                
                                let updatedImage = IUser.Image(
                                    asset: userDefaultsData.asset,
                                    _type: userDefaultsData._type,
                                    url: userDefaultsData.url
                                )
                                UserDefaults.image = updatedImage
                                
                            case .failure(let error):
                                print(error)
                            }
                        }
                        isLoggedIn = true
                        completion(.success("success"))
                    } else if let wrongPassword = responseData["wrongPassword"] as? Bool, wrongPassword {
                        print("Wrong password")
                        completion(.failure(LoginError.wrongPassword))
                    } else if let accountNotFound = responseData["accountNotFound"] as? Bool, accountNotFound {
                        print("Account not found in the database")
                        completion(.failure(LoginError.accountNotFound))
                    }
                }
            } else {
                // Handle the case where fetching CSRF data failed
                print("Failed to fetch CSRF data")
            }
        } catch {
            print("Error handling login:", error)
            completion(.failure(error))
        }
    }

    func getUserDefaultaData(userProfileId: String, completion: @escaping (Result<IUser.Image, Error>) -> Void) {
        guard let serverIPUrl = ProcessInfo.processInfo.environment["serverIpUrl"],
              var searchUserUrl = URLComponents(string: "\(serverIPUrl)/api/profileUserDefaults") else {
            print("Invalid server URL")
            return
        }

        // Add userProfileId as a query parameter
        searchUserUrl.queryItems = [URLQueryItem(name: "userProfileId", value: userProfileId)]

        guard let finalUrl = searchUserUrl.url else {
            print("Error creating final URL")
            return
        }

        var request = URLRequest(url: finalUrl)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error making GET request:", error)
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                let error = NSError(domain: "com.example.app", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                completion(.failure(error))
                return
            }

            if httpResponse.statusCode == 200 {
                print("GET request successful")

                // Deserialize the JSON response as IUser.Image
                do {
                    let decoder = JSONDecoder()
                    if let data = data {
                        let response = try decoder.decode([String: IUser.Image].self, from: data)
                        if let userDefaultsData = response["image"] {
                            print("userDefaultsData:", userDefaultsData)
                            
                            completion(.success(userDefaultsData))
                        } else {
                            print("Image data not found in response")
                            completion(.failure(NSError(domain: "com.example.app", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image data not found in response"])))
                        }
                    } else {
                        print("No data received")
                        completion(.failure(NSError(domain: "com.example.app", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    }

                } catch {
                    print("Error decoding response data:", error)
                    completion(.failure(error))
                }
            } else {
                print("GET request failed with status code:", httpResponse.statusCode)
                // Handle failure response if needed
            }
        }

        task.resume()
    }



}

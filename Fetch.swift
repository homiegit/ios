import Foundation
import os.log

struct VideoWordData: Codable {
    let videos: [Video]
    let words: [Word]
}

struct UserData: Codable {
    let videos: [Video]
    //let words: [Word]
    let user: IUser
    let counts: Counts?
}

struct MinimumUserData: Codable {
    let userName: String
    let image: String
}

class Refresh {
    func refreshVideos(completion: @escaping ([Video]) -> Void) {
        guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
              let refreshVideosEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/refreshVideos") else {
            print("Error: Invalid server URL or endpoint")
            return
        }
        print("refreshVideosEndpoint:", refreshVideosEndpoint)

        var request = URLRequest(url: refreshVideosEndpoint)
        request.httpMethod = "POST"
        
        var postDataString = ""
        if let userId = UserDefaults.userProfile?._id {
            postDataString = "userId=\(userId)"
        }
        request.httpBody = postDataString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            print("Raw Server Response (JSON):")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("jsonString:", jsonString)
            } else {
                print("Failed to convert data to string.")
            }

            do {
                let decoder = JSONDecoder()
                let videoData = try decoder.decode([Video].self, from: data)
                print("videoData:", videoData)

                completion(videoData)
            } catch {
                print("Error decoding JSON:", error)
            }
        }.resume()
    }

    
    func refreshWords(completion: @escaping ([Word]) -> Void) {

        guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
              let refreshWordsEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/refreshWords") else {
            print("Error: Invalid server URL or endpoint")
            return
        }
        print("refreshWordsEndpoint:", refreshWordsEndpoint)

        var request = URLRequest(url: refreshWordsEndpoint)
        request.httpMethod = "POST"
        
        var postDataString = "userId=\("")"
        if let userId = UserDefaults.userProfile?._id {
            postDataString = "userId=\(userId)"
        }
        request.httpBody = postDataString.data(using: .utf8)
       
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            print("Raw Server Response (JSON):")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("jsonString:", jsonString)
            } else {
                print("Failed to convert data to string.")
            }
            
            do {
                let decoder = JSONDecoder()
                let wordData = try decoder.decode([Word].self, from: data)
                print("wordData:", wordData)
                
                completion(wordData)
            } catch {
                print("Error decoding JSON:", error)
            }
        }.resume()
        
    }
}

class UsersFromPosts {
    func fetchUsers(forRefs _refs: [String], completion: @escaping ([IUser]) -> Void) {
        guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
              let usersEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/users") else {
            print("Error: Invalid server URL or endpoint")
            return
        }
        //print("usersEndpoint:", usersEndpoint)

        // Create a dictionary containing the _refs array and convert it to JSON data
        let requestData: [String: Any] = ["_refs": _refs]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            print("Error encoding JSON data")
            return
        }

        var request = URLRequest(url: usersEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let decoder = JSONDecoder()
                let users = try decoder.decode([IUser].self, from: data)
                print("users:", users)

                completion(users)

            } catch {
                print("Error decoding JSON:", error)
            }
        }.resume()
    }
}

    func fetchComments(forRefs _refs: [String], completion: @escaping ([IComment]) -> Void) {
        guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
              let fetchCommentEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/fetchComment") else {
            print("Error: Invalid server URL or endpoint")
            return
        }
        print("fetchCommentEndpoint:", fetchCommentEndpoint)

        // Create a dictionary containing the _refs array and convert it to JSON data
        let requestData: [String: Any] = ["_refs": _refs]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            print("Error encoding JSON data")
            return
        }

        var request = URLRequest(url: fetchCommentEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let decoder = JSONDecoder()
                let comment = try decoder.decode([IComment].self, from: data)
                print("comment:", comment)

                completion(comment)

            } catch {
                print("Error decoding JSON:", error)
            }
        }.resume()
    }


class ProfileData {
    func fetchUserData(_ profileRef: String, completion: @escaping (Result<UserData, Error>) -> Void) {
        guard let serverIpUrlString = ProcessInfo.processInfo.environment["serverIpUrl"],
              let profileDataEndpoint = URL(string: serverIpUrlString)?.appendingPathComponent("/api/profileData") else {
            print("Error: Invalid server URL or endpoint")
            return
        }
        print("profileDataEndpoint:", profileDataEndpoint)
        
        let requestData: [String: Any] = ["profileRef": profileRef, "userId": UserDefaults.userProfile?._id ?? "unknown"]
        print("Request JSON Data:", requestData)

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData) else {
            print("Error encoding JSON data")
            return
        }
        
        let jsonString = String(data: jsonData, encoding: .utf8)
        print("Request JSON Data:", jsonString ?? "")


        var request = URLRequest(url: profileDataEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }
            
            print("Raw Server Response (JSON):", data)


            do {
                let decoder = JSONDecoder()
                let profileData = try decoder.decode(UserData.self, from: data)
                print("profileData:", profileData)

                completion(.success(profileData))

            } catch {
                print("Error decoding JSON:", error)
            }
        }.resume()
    }
}



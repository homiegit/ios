//
//  homie_iosApp.swift
//  homie-ios
//
//  Created by Diego Lares on 7/25/23.
//

import SwiftUI

@main
struct homie_iosApp: App {
    @StateObject var viewRouter = ViewRouter()
    @StateObject var topicsViewModel = TopicsViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView(
//                videos: [
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
//            ],
//                isPlayingArray: Array(repeating: false, count: 1)
            )
                .environmentObject(viewRouter)
                .environmentObject(topicsViewModel)
                .alert(isPresented: $viewRouter.isVideoSaved) {
                    Alert(title: Text("Your video has been posted!"), message: nil, dismissButton: .default(Text("OK")))
                }
        }
    }
}



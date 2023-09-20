
import Foundation

struct Proof: Codable {
    let text: String?
    let sources: [UserBibleSource]?
    let flag: String?
}

struct BibleSource: Codable, Hashable {
    var book: String
    var chapter: Int
}

struct UserBibleSource: Codable, Hashable {
    var book: String
    var chapter: Int
}

struct UserUrlSource: Codable, Hashable {
    var url: String
    var title: String
    var _key: String
    
    // Implement the hash(into:) method
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(title)
    }
    
    // Implement the == operator
    static func ==(lhs: UserUrlSource, rhs: UserUrlSource) -> Bool {
        return lhs.url == rhs.url && lhs.title == rhs.title
    }
}

struct UserRef: Codable {
    let _ref: String
    let _type: String
}

struct ViewData: Codable {
    let timeViewed: String
    let secondsWatched: Double
}

struct Video: Codable {

    struct IsVideoReliable: Codable {
        let reliability: String
        let proof: Proof?
    }

    struct Asset: Codable {
        let _id: String
        let url: URL
    }
    
    struct Watched: Codable {
        let userRef: UserRef
        let viewData: ViewData
    }
    
    struct Claims: Codable {
        let claim: String
        let reliability: String
    }
    
    let _type: String?
    let isVideoReliable: IsVideoReliable
    let isFeatured: Bool?
    let videoUrl: URL?
    let caption: String?
    let urlSources: [UserUrlSource]?
    let bibleSources: [UserBibleSource]?
    let selectedTopics: [String]?
    let typeOfContent: [String]?
    let transcriptionResults: String?
    let cues: [Items]?
    let transcription: String?
    let onlyWordsTranscription: [String]?
    let godKeywords: [String]?
    let translatedText: String?
    let claims: [Claims]?
    let videoId: String?
    let createdAt: String?
    let timeAgo: String?
    let video: VideoAsset?
    let _id: String?
    let postedBy: PostedBy
    let likes: [Like]?
    let dislikes: [Dislike]?
    let comments: [Comment]?
    let views: [Watched]?
    let averageSecondsWatched: Double?
}

struct Items: Codable, Hashable {
    struct Alternative: Codable, Hashable {
        let confidence: Double
        let content: String
        let _key: String
    }

    let alternatives: [Alternative]?
    let start_time: Double?
    let end_time: Double?
    let _key: String?
    
    // Implement Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(_key)
    }
    
    // Implement Equatable conformance
    static func ==(lhs: Items, rhs: Items) -> Bool {
        return lhs._key == rhs._key
    }
}


struct UploadedAsset: Codable {
    let url: String
    let `extension`: String
    let originalFilename: String
}

struct VideoAsset: Codable {
    let asset: Asset
    let videoUrl: URL?
}

struct Asset: Codable {
    let _type: String
    let _ref: String
}

struct PostedBy: Codable {
    let _ref: String
}

struct Like: Codable {
    let _ref: String
}

struct Dislike: Codable {
    let _ref: String
}

struct Comment: Codable {
    let _ref: String
}

struct Word: Codable {
    let image: String?
    let text: String
    
    struct IsWordReliable: Codable {
        let reliability: String
        let proof: [Proof]?
    }
    let isWordReliable: IsWordReliable?
    let selectedTopics: [String]?
    let wordId: String?
    let urlSources: [UserUrlSource]?
    let bibleSources: [UserBibleSource]?

    let _id: String?
    let isFeatured: Bool?
    let _createdAt: String?
    let timeAgo: String?
    let postedBy: PostedBy
    let likes: [Like]?
    let comments: [Comment]?
}

struct IComment: Codable {
    let _type: String
    let comment: String
    //let commentId: UUID?
    let _id: UUID
    //let _key: String?
    struct CommentedOn: Codable {
        let _ref: String
        let _type: String
    }
    let commentedOn: CommentedOn
    struct IsCommentReliable: Codable {
        let reliability: String
        let proof: Proof?
    }
    let isCommentReliable: IsCommentReliable
    let postedBy: PostedBy
    let likes: [Like]?
    let dislikes: [Dislike]?
}

struct Report: Codable {
    let postedBy: String
    let videoId: String
    let text: String
}

//

struct IUser: Codable {
    struct Image: Codable {
        struct Asset: Codable {
            let _ref: String
            let _type: String
        }
        let asset: Asset?
        let _type: String?
        let url: String?
    }

    struct IUserProof: Codable {
        let text: String?
        struct Source: Codable {
            let video: Asset?
            let word: Asset?
        }
        let sources: [IUserProof.Source]?
        let flag: String?
    }

    let id: String?
    let _id: String
    let _type: String?
    let userName: String
    let image: Image?
    struct IsUserReliable: Codable {
        let reliability: String?
        let proof: [IUserProof]?
    }
    let isUserReliable: IsUserReliable?
    struct VideosWatched: Codable {
        let videoRef: String
        let secondsWatched: Int
    }
    let videosWatched: [VideosWatched]?
    let interestedContent: [String]?
    let counts: Counts?
}

struct Counts: Codable {
    var wordPercentTrue: Int?
    var totalWordsCount: Int?
    var reliableWordsCount: Int?
    var inaccurateWordsCount: Int?
    var pendingWordsCount: Int?
    var falseWordsCount: Int?
    var videoPercentTrue: Int?
    var totalVideosCount: Int?
    var reliableVideosCount: Int?
    var inaccurateVideosCount: Int?
    var pendingVideosCount: Int?
    var falseVideosCount: Int?
    var allPerReviewed: Int?
    var allTotalReviewed: Int?
    var trueVideosPerReviewed: Int?
    var trueWordsPerReviewed: Int?
    var allPercentTrue: Int?
    var countedTrueReviewed: Int?

    // Custom init for Decodable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wordPercentTrue = try container.decodeIfPresent(Int.self, forKey: .wordPercentTrue)
        totalWordsCount = try container.decodeIfPresent(Int.self, forKey: .totalWordsCount)
        reliableWordsCount = try container.decodeIfPresent(Int.self, forKey: .reliableWordsCount)
        inaccurateWordsCount = try container.decodeIfPresent(Int.self, forKey: .inaccurateWordsCount)
        pendingWordsCount = try container.decodeIfPresent(Int.self, forKey: .pendingWordsCount)
        falseWordsCount = try container.decodeIfPresent(Int.self, forKey: .falseWordsCount)
        videoPercentTrue = try container.decodeIfPresent(Int.self, forKey: .videoPercentTrue)
        totalVideosCount = try container.decodeIfPresent(Int.self, forKey: .totalVideosCount)
        reliableVideosCount = try container.decodeIfPresent(Int.self, forKey: .reliableVideosCount)
        inaccurateVideosCount = try container.decodeIfPresent(Int.self, forKey: .inaccurateVideosCount)
        pendingVideosCount = try container.decodeIfPresent(Int.self, forKey: .pendingVideosCount)
        falseVideosCount = try container.decodeIfPresent(Int.self, forKey: .falseVideosCount)
        allPerReviewed = try container.decodeIfPresent(Int.self, forKey: .allPerReviewed)
        allTotalReviewed = try container.decodeIfPresent(Int.self, forKey: .allTotalReviewed)
        trueVideosPerReviewed = try container.decodeIfPresent(Int.self, forKey: .trueVideosPerReviewed)
        trueWordsPerReviewed = try container.decodeIfPresent(Int.self, forKey: .trueWordsPerReviewed)
        allPercentTrue = try container.decodeIfPresent(Int.self, forKey: .allPercentTrue)
        countedTrueReviewed = try container.decodeIfPresent(Int.self, forKey: .countedTrueReviewed)
    }
}

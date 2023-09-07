//
//  Configurations.swift
//  homie-ios
//
//  Created by Diego Lares on 7/25/23.
//

import Foundation

struct Configurations {
    static let sanityProjectId = "ynqkzz99"
    static let sanityApiVersion = "2022-03-10"
    static let sanityToken = "sk4buoJv9XSRRGfR4RxYwH1MpNO0VMr86aKkdLrk5JiNLHPdfSuDVRSuhZ1n8aV2UpqI7kSiOlfzkpIKPt2bVs30iky1AqM9pEJezdikpovDs8QryXk9AdN9t5J31QRSyXxmAb8XL0Wgoar0BKMEhqlrg6HlfhjMDxKJ7QeS5bAm9wTCYHCt"
    static let serverUrl = "http://localhost:3031"
    static let serverIpUrl = "http://192.168.0.202:3031"
    static let baseUrl = "http://localhost:3000"
    static let astraDbId = "3b469f23-7e47-49e1-9a30-90541d75aa22"
    static let astraDbRegion = "us-east1"
    static let astraDbApplicationToken = "AstraCS:QPFoXXgNTKuGKueyzvUtlylt:e0b4ca519d84d18e0748b1c4f2b5795b6b205e88eae814a4efb111c7f35103bb"
    static let astraDbClientId = "QPFoXXgNTKuGKueyzvUtlylt"
    static let astraDbClientSecret = "D7UPeS9MDPuDeeGf6MvyvM5RjSDTIXCAAz2DaO6qcT0qs3cIn+7t14bQbkftu268gZYXNPkL+s9aOvKipsKYzYcocYrR8e0xaF9aKdhurb2nbQ7JGky4-yHe_Z5Ml5ic"
    static let astraDbKeyspace = "test"
    static let datastaxUsername = "lares_diego@yahoo.com"
    static let datastaxPassword = "P!n2LCMBfctJ2LH"
    static let awsAccessKey = "AKIAU4N7DHM6F3NSOTCD"
    static let awsSecretAccessKey = "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"
    static let awsBucketname = "transcribebucket5"
    static let awsMp4Bucketname = "mp4files1"
    static let awsOutputBucketname = "outputtranscribebucket2"

    // Retrieve the values from environment variables
    static var sanityProjectIdValue: String? {
        return ProcessInfo.processInfo.environment[sanityProjectId]
    }

    static var sanityApiVersionValue: String? {
        return ProcessInfo.processInfo.environment[sanityApiVersion]
    }
    
    static var sanityTokenValue: String? {
        return ProcessInfo.processInfo.environment[sanityToken]
    }
    
    static var serverUrlValue: String {
        return ProcessInfo.processInfo.environment[serverUrl]!
    }
    
    static var serverIpUrlValue: String {
        print("serverIpUrl:", serverIpUrl)
        return ProcessInfo.processInfo.environment[serverIpUrl] ?? ""
    }
    
    static var baseUrlValue: String? {
        return ProcessInfo.processInfo.environment[baseUrl]
    }
    
    static var astraDbIdValue: String? {
        return ProcessInfo.processInfo.environment[astraDbId]
    }
    
    static var astraDbRegionValue: String? {
        return ProcessInfo.processInfo.environment[astraDbRegion]
    }
    
    static var astraDbApplicationTokenValue: String? {
        return ProcessInfo.processInfo.environment[astraDbApplicationToken]
    }
    
    static var astraDbClientIdValue: String? {
        return ProcessInfo.processInfo.environment[astraDbClientId]
    }
    
    static var astraDbClientSecretValue: String? {
        return ProcessInfo.processInfo.environment[astraDbClientSecret]
    }
    
    static var astraDbKeyspaceValue: String? {
        return ProcessInfo.processInfo.environment[astraDbKeyspace]
    }
    
    static var datastaxUsernameValue: String? {
        return ProcessInfo.processInfo.environment[datastaxUsername]
    }
    
    static var datastaxPasswordValue: String? {
        return ProcessInfo.processInfo.environment[datastaxPassword]
    }
    
    static var awsAccessKeyValue: String? {
        return ProcessInfo.processInfo.environment[awsAccessKey]
    }
    
    static var awsSecretAccessKeyValue: String? {
        return ProcessInfo.processInfo.environment[awsSecretAccessKey]
    }
    
    static var awsBucketnameValue: String? {
        return ProcessInfo.processInfo.environment[awsBucketname]
    }
    
    static var awsMp4BucketnameValue: String? {
        return ProcessInfo.processInfo.environment[awsMp4Bucketname]
    }
    
    static var awsOutputBucketnameValue: String? {
        return ProcessInfo.processInfo.environment[awsOutputBucketname]
    }
}

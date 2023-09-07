import Foundation
import CommonCrypto

class KeychainManager {
    enum KeychainError: Error {
        case encryptionFailed
        case decryptionFailed
    }

    static func saveUsername(_ username: String, forService service: String) {
        let data = Data(username.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadUsername(forService service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess,
           let queryResult = result as? [String: Any],
           let usernameData = queryResult[kSecAttrAccount as String] as? Data,
           let username = String(data: usernameData, encoding: .utf8) {
            return username
        }
        return nil
    }

    static func deleteUsername(forService service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func deletePassword(forService service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }

//    internal static func encryptData(_ data: Data, withKey key: String) throws -> Data {
//            let keyData = key.data(using: .utf8)!
//            let options = CCOptions(kCCOptionPKCS7Padding)
//
//            var numBytesEncrypted: size_t = 0
//
//            var encryptedData: Data
//            do {
//                encryptedData = Data(count: data.count + kCCBlockSizeAES128)
//                try data.withUnsafeBytes { dataBytes in
//                    guard let dataBaseAddress = dataBytes.baseAddress else {
//                        throw KeychainError.encryptionFailed
//                    }
//
//                    try keyData.withUnsafeBytes { keyBytes in
//                        guard let keyBaseAddress = keyBytes.baseAddress else {
//                            throw KeychainError.encryptionFailed
//                        }
//
//                        try encryptedData.withUnsafeMutableBytes { encryptedBytes in
//                            guard let encryptedBaseAddress = encryptedBytes.baseAddress else {
//                                throw KeychainError.encryptionFailed
//                            }
//
//                            CCCrypt(CCOperation(kCCEncrypt),
//                                    CCAlgorithm(kCCAlgorithmAES),
//                                    options,
//                                    keyBaseAddress, kCCKeySizeAES128,
//                                    nil,
//                                    dataBaseAddress, data.count,
//                                    encryptedBaseAddress, encryptedData.count,
//                                    &numBytesEncrypted)
//                        }
//                    }
//                }
//            } catch {
//                throw KeychainError.encryptionFailed
//            }
//
//            if numBytesEncrypted > 0 {
//                encryptedData.count = numBytesEncrypted
//                return encryptedData
//            } else {
//                throw KeychainError.encryptionFailed
//            }
//        }
//
//        internal static func decryptData(_ encryptedData: Data, withKey key: String) throws -> Data {
//            let keyData = key.data(using: .utf8)!
//            let options = CCOptions(kCCOptionPKCS7Padding)
//
//            var numBytesDecrypted: size_t = 0
//
//            var decryptedData: Data
//            do {
//                decryptedData = Data(count: encryptedData.count + kCCBlockSizeAES128)
//                try encryptedData.withUnsafeBytes { encryptedBytes in
//                    guard let encryptedBaseAddress = encryptedBytes.baseAddress else {
//                        throw KeychainError.decryptionFailed
//                    }
//
//                    try keyData.withUnsafeBytes { keyBytes in
//                        guard let keyBaseAddress = keyBytes.baseAddress else {
//                            throw KeychainError.decryptionFailed
//                        }
//
//                        try decryptedData.withUnsafeMutableBytes { decryptedBytes in
//                            guard let decryptedBaseAddress = decryptedBytes.baseAddress else {
//                                throw KeychainError.decryptionFailed
//                            }
//
//                            CCCrypt(CCOperation(kCCDecrypt),
//                                    CCAlgorithm(kCCAlgorithmAES),
//                                    options,
//                                    keyBaseAddress, kCCKeySizeAES128,
//                                    nil,
//                                    encryptedBaseAddress, encryptedData.count,
//                                    decryptedBaseAddress, decryptedData.count,
//                                    &numBytesDecrypted)
//                        }
//                    }
//                }
//            } catch {
//                throw KeychainError.decryptionFailed
//            }
//
//            if numBytesDecrypted > 0 {
//                decryptedData.count = numBytesDecrypted
//                return decryptedData
//            } else {
//                throw KeychainError.decryptionFailed
//            }
//        }
//
//        static func savePassword(_ password: String, forService service: String, withEncryptionKey key: String) {
//            do {
//                let dataToSave = try encryptData(Data(password.utf8), withKey: key)
//                let query: [String: Any] = [
//                    kSecClass as String: kSecClassGenericPassword,
//                    kSecAttrService as String: service,
//                    kSecAttrAccount as String: "password",
//                    kSecValueData as String: dataToSave
//                ]
//                SecItemAdd(query as CFDictionary, nil)
//            } catch {
//                print("Error saving password:", error)
//            }
//        }

//        static func loadPassword(forService service: String, withEncryptionKey key: String) -> String? {
//            let query: [String: Any] = [
//                kSecClass as String: kSecClassGenericPassword,
//                kSecAttrService as String: service,
//                kSecAttrAccount as String: "password",
//                kSecReturnData as String: kCFBooleanTrue!,
//                kSecMatchLimit as String: kSecMatchLimitOne
//            ]
//
//            var result: AnyObject?
//            let status = SecItemCopyMatching(query as CFDictionary, &result)
//            if status == errSecSuccess, let passwordData = result as? Data {
//                do {
//                    let decryptedData = try decryptData(passwordData, withKey: key)
//                    if let password = String(data: decryptedData, encoding: .utf8) {
//                        return password
//                    }
//                } catch {
//                    print("Error loading password:", error)
//                }
//            }
//            return nil
//        }
    
    static func saveUserID(_ id: Int, forService service: String) {
            var mutableID = id
            let data = Data(bytes: &mutableID, count: MemoryLayout<Int>.size)

            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecValueData: data
            ]

            SecItemDelete(query as CFDictionary)

            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                print("Failed to save user ID to Keychain: \(status)")
            }
        }

        static func getUserID(forService service: String) -> Int? {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecMatchLimit: kSecMatchLimitOne,
                kSecReturnData: kCFBooleanTrue as Any,
                kSecReturnAttributes: kCFBooleanTrue as Any
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            if status == errSecSuccess, let existingItem = result as? [String: Any], let data = existingItem[kSecValueData as String] as? Data {
                var userID: Int = 0
                data.withUnsafeBytes { bufferPointer in
                    if bufferPointer.count == MemoryLayout<Int>.size {
                        userID = bufferPointer.load(as: Int.self)
                    }
                }
                return userID
            } else {
                return nil
            }
        }

    }

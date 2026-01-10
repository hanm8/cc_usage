import Foundation
import Security

struct ClaudeCredentials: Codable {
    let claudeAiOauth: OAuthCredentials?
}

struct OAuthCredentials: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Int64?
    let subscriptionType: String?
    let rateLimitTier: String?
}

enum CredentialError: Error, LocalizedError {
    case fileNotFound
    case fileNotReadable
    case invalidJSON(Error)
    case missingOAuthData
    case keychainAccessFailed(Int32)
    case keychainDataCorrupted

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Credentials file not found"
        case .fileNotReadable:
            return "Cannot read credentials file"
        case .invalidJSON(let error):
            return "Invalid credentials format: \(error.localizedDescription)"
        case .missingOAuthData:
            return "OAuth credentials missing"
        case .keychainAccessFailed(let status):
            return "Keychain access failed (status: \(status))"
        case .keychainDataCorrupted:
            return "Keychain data corrupted"
        }
    }
}

actor CredentialService {
    static let shared = CredentialService()

    private let credentialsPath: String
    private let keychainService = "Claude Code-credentials"
    private let fileManager = FileManager.default

    // Cache credentials to avoid repeated file/keychain access
    private var cachedCredentials: OAuthCredentials?
    private var cacheTimestamp: Date?
    private let cacheValiditySeconds: TimeInterval = 60

    init() {
        let home = fileManager.homeDirectoryForCurrentUser
        credentialsPath = home.appendingPathComponent(".claude/.credentials.json").path
    }

    func credentialsFileExists() -> Bool {
        fileManager.fileExists(atPath: credentialsPath)
    }

    func getAccessToken() -> String? {
        do {
            let credentials = try getCredentialsWithCache()
            return credentials.accessToken
        } catch {
            return nil
        }
    }

    func getCredentials() -> OAuthCredentials? {
        try? getCredentialsWithCache()
    }

    func isTokenExpired() -> Bool {
        guard let creds = getCredentials(),
              let expiresAt = creds.expiresAt else {
            return true
        }

        let expirationDate = Date(timeIntervalSince1970: Double(expiresAt) / 1000)
        // Consider expired if within 5 minutes of expiration (buffer for clock skew)
        return Date().addingTimeInterval(300) > expirationDate
    }

    func clearCache() {
        cachedCredentials = nil
        cacheTimestamp = nil
    }

    // MARK: - Private Methods

    private func getCredentialsWithCache() throws -> OAuthCredentials {
        // Return cached credentials if still valid
        if let cached = cachedCredentials,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheValiditySeconds {
            return cached
        }

        // Try file first, then keychain
        let credentials: OAuthCredentials
        if let fileCreds = try? getCredentialsFromFile() {
            credentials = fileCreds
        } else if let keychainCreds = try? getCredentialsFromKeychain() {
            credentials = keychainCreds
        } else {
            throw CredentialError.missingOAuthData
        }

        // Update cache
        cachedCredentials = credentials
        cacheTimestamp = Date()

        return credentials
    }

    private func getCredentialsFromFile() throws -> OAuthCredentials {
        guard fileManager.fileExists(atPath: credentialsPath) else {
            throw CredentialError.fileNotFound
        }

        guard let data = fileManager.contents(atPath: credentialsPath) else {
            throw CredentialError.fileNotReadable
        }

        let credentials: ClaudeCredentials
        do {
            credentials = try JSONDecoder().decode(ClaudeCredentials.self, from: data)
        } catch {
            throw CredentialError.invalidJSON(error)
        }

        guard let oauth = credentials.claudeAiOauth else {
            throw CredentialError.missingOAuthData
        }

        return oauth
    }

    private func getCredentialsFromKeychain() throws -> OAuthCredentials {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", keychainService, "-w"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw CredentialError.keychainAccessFailed(-1)
        }

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw CredentialError.keychainAccessFailed(process.terminationStatus)
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

        guard let jsonString = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !jsonString.isEmpty else {
            throw CredentialError.keychainDataCorrupted
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw CredentialError.keychainDataCorrupted
        }

        let credentials: ClaudeCredentials
        do {
            credentials = try JSONDecoder().decode(ClaudeCredentials.self, from: jsonData)
        } catch {
            throw CredentialError.invalidJSON(error)
        }

        guard let oauth = credentials.claudeAiOauth else {
            throw CredentialError.missingOAuthData
        }

        return oauth
    }
}

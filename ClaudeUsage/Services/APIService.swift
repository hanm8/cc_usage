import Foundation

actor APIService {
    static let shared = APIService()

    private let baseURL = "https://api.anthropic.com"
    private let credentialService = CredentialService.shared
    private let userAgent = "claude-code/2.1.7"
    private let maxRetries = 3
    private let retryDelay: UInt64 = 1_000_000_000 // 1 second in nanoseconds

    private enum Endpoint: String {
        case usage = "/api/oauth/usage"
        case profile = "/api/oauth/profile"
    }

    func fetchUsage() async throws -> UsageResponse {
        try await performRequest(endpoint: .usage)
    }

    func fetchProfile() async throws -> ProfileResponse {
        try await performRequest(endpoint: .profile)
    }

    func refreshToken() async throws {
        guard let refreshToken = await credentialService.getCredentials()?.refreshToken else {
            throw APIError.noRefreshToken
        }

        guard let url = URL(string: "\(baseURL)/api/oauth/token") else {
            throw APIError.invalidURL("/api/oauth/token")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let body = ["refresh_token": refreshToken, "grant_type": "refresh_token"]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.tokenRefreshFailed(httpResponse.statusCode)
        }

        // Note: We can't save the new token here as we don't have write access
        // This would need to be handled by the credential service
        _ = data
    }

    private func performRequest<T: Decodable>(endpoint: Endpoint) async throws -> T {
        let token = try await getToken()
        let request = try buildRequest(endpoint: endpoint, token: token)

        var lastError: Error = APIError.networkUnavailable

        for attempt in 1...maxRetries {
            do {
                return try await executeRequest(request)
            } catch let error as APIError {
                switch error {
                case .networkError, .timeout:
                    // Retry on transient network errors
                    lastError = error
                    if attempt < maxRetries {
                        try await Task.sleep(nanoseconds: retryDelay * UInt64(attempt))
                        continue
                    }
                case .serverError:
                    // Retry on 5xx errors
                    lastError = error
                    if attempt < maxRetries {
                        try await Task.sleep(nanoseconds: retryDelay * UInt64(attempt))
                        continue
                    }
                default:
                    // Don't retry on client errors (4xx), auth errors, etc.
                    throw error
                }
            } catch {
                lastError = APIError.networkError(error)
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: retryDelay * UInt64(attempt))
                    continue
                }
            }
        }

        throw lastError
    }

    private func getToken() async throws -> String {
        guard let token = await credentialService.getAccessToken() else {
            if await credentialService.credentialsFileExists() {
                throw APIError.credentialsCorrupted
            }
            throw APIError.noToken
        }

        if await credentialService.isTokenExpired() {
            throw APIError.tokenExpired
        }

        return token
    }

    private func buildRequest(endpoint: Endpoint, token: String) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(endpoint.rawValue)") else {
            throw APIError.invalidURL(endpoint.rawValue)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        return request
    }

    private func executeRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        try validateHTTPResponse(httpResponse, data: data)

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            throw APIError.decodingError(decodingError)
        }
    }

    private func validateHTTPResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.tokenExpired
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 429:
            throw APIError.rateLimited
        case 400...499:
            let message = extractErrorMessage(from: data)
            throw APIError.clientError(response.statusCode, message)
        case 500...599:
            throw APIError.serverError(response.statusCode)
        default:
            throw APIError.httpError(response.statusCode)
        }
    }

    private func extractErrorMessage(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            let error: ErrorDetail?
            let message: String?

            struct ErrorDetail: Decodable {
                let message: String?
            }
        }

        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return errorResponse.error?.message ?? errorResponse.message
        }
        return nil
    }

    private func mapURLError(_ error: URLError) -> APIError {
        switch error.code {
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .hostUnreachable
        case .secureConnectionFailed, .serverCertificateUntrusted:
            return .sslError
        case .cancelled:
            return .cancelled
        default:
            return .networkError(error)
        }
    }
}

enum APIError: Error, LocalizedError {
    case noToken
    case tokenExpired
    case noRefreshToken
    case tokenRefreshFailed(Int)
    case credentialsCorrupted
    case invalidURL(String)
    case invalidResponse
    case decodingError(DecodingError)
    case httpError(Int)
    case clientError(Int, String?)
    case serverError(Int)
    case forbidden
    case notFound
    case rateLimited
    case networkError(Error)
    case networkUnavailable
    case hostUnreachable
    case timeout
    case sslError
    case cancelled

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No credentials found. Start Claude to login"
        case .tokenExpired:
            return "Session expired. Start Claude to refresh"
        case .noRefreshToken:
            return "No refresh token. Start Claude to refresh"
        case .tokenRefreshFailed(let code):
            return "Token refresh failed (\(code)). Start Claude to refresh"
        case .credentialsCorrupted:
            return "Credentials corrupted. Start Claude to login"
        case .invalidURL(let path):
            return "Invalid endpoint: \(path)"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .clientError(let code, let message):
            if let message = message {
                return "Request failed (\(code)): \(message)"
            }
            return "Request failed: \(code)"
        case .serverError(let code):
            return "Server error (\(code)). Try again later."
        case .forbidden:
            return "Access denied. Check your subscription."
        case .notFound:
            return "API endpoint not found"
        case .rateLimited:
            return "Rate limited. Please wait."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .networkUnavailable:
            return "No internet connection"
        case .hostUnreachable:
            return "Cannot reach server"
        case .timeout:
            return "Request timed out"
        case .sslError:
            return "Secure connection failed"
        case .cancelled:
            return "Request cancelled"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkError, .networkUnavailable, .hostUnreachable, .timeout, .serverError:
            return true
        default:
            return false
        }
    }

    var requiresReauthentication: Bool {
        switch self {
        case .noToken, .tokenExpired, .noRefreshToken, .tokenRefreshFailed, .credentialsCorrupted:
            return true
        default:
            return false
        }
    }
}

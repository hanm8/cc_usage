import SwiftUI

@main
struct ClaudeUsageApp: App {
    @StateObject private var usageViewModel = UsageViewModel()
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(usageViewModel)
        } label: {
            HStack(spacing: 4) {
                if let usage = usageViewModel.usage {
                    // 5-Hour Limit
                    Image(systemName: "clock.arrow.circlepath")
                        .accessibilityLabel("5-hour limit")
                    Text(String(format: "%.0f%%", usage.fiveHour?.utilization ?? 0))

                    Text("•")
                        .foregroundColor(.secondary)

                    // 7-Day Limit
                    Image(systemName: "chart.bar.xaxis")
                        .accessibilityLabel("7-day limit")
                    Text(String(format: "%.0f%%", usage.sevenDay?.utilization ?? 0))
                } else {
                    if usageViewModel.isLoading {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .accessibilityLabel("Loading usage data")
                    } else if usageViewModel.error != nil {
                        Image(systemName: "exclamationmark.triangle")
                            .accessibilityLabel("Error loading usage data")
                    } else {
                        Image(systemName: "brain.head.profile")
                            .accessibilityLabel("Claude usage")
                    }
                }
            }
            .font(.system(.body, design: .rounded))
        }
        .menuBarExtraStyle(.window) // Switch to window style for custom view
    }
}

@MainActor
class UsageViewModel: ObservableObject {
    @Published var usage: UsageResponse?
    @Published var profile: ProfileResponse?
    @Published var errorState: ErrorState?
    @Published var isLoading = false

    private let apiService = APIService.shared
    private var refreshTimer: Timer?
    private var consecutiveFailures = 0
    private let maxConsecutiveFailures = 5

    var error: String? {
        errorState?.message
    }

    init() {
        startRefreshTimer()
        Task {
            await refresh()
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }

    func refresh() async {
        // Don't refresh if already loading
        guard !isLoading else { return }

        isLoading = true

        do {
            async let usageTask = apiService.fetchUsage()
            async let profileTask = apiService.fetchProfile()

            let (usageResult, profileResult) = try await (usageTask, profileTask)

            usage = usageResult
            profile = profileResult
            errorState = nil
            consecutiveFailures = 0
        } catch let apiError as APIError {
            handleAPIError(apiError)
        } catch {
            errorState = ErrorState(
                type: .unknown,
                message: error.localizedDescription,
                isRecoverable: true
            )
            consecutiveFailures += 1
        }

        isLoading = false

        // Pause auto-refresh if too many consecutive failures
        if consecutiveFailures >= maxConsecutiveFailures {
            pauseAutoRefresh()
        }
    }

    private func handleAPIError(_ error: APIError) {
        consecutiveFailures += 1

        let errorType: ErrorState.ErrorType
        let isRecoverable: Bool
        let actionHint: String?

        switch error {
        case .noToken, .tokenExpired, .credentialsCorrupted:
            errorType = .authentication
            isRecoverable = false
            actionHint = "Run: claude login"
        case .networkUnavailable:
            errorType = .network
            isRecoverable = true
            actionHint = "Check your internet connection"
        case .hostUnreachable, .timeout:
            errorType = .network
            isRecoverable = true
            actionHint = "Server may be temporarily unavailable"
        case .rateLimited:
            errorType = .rateLimit
            isRecoverable = true
            actionHint = "Please wait a moment"
        case .forbidden:
            errorType = .permission
            isRecoverable = false
            actionHint = "Check your subscription status"
        case .serverError:
            errorType = .server
            isRecoverable = true
            actionHint = "Try again later"
        case .cancelled:
            // Don't show error for cancelled requests
            return
        default:
            errorType = .unknown
            isRecoverable = true
            actionHint = nil
        }

        errorState = ErrorState(
            type: errorType,
            message: error.localizedDescription,
            isRecoverable: isRecoverable,
            actionHint: actionHint
        )
    }

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.refresh()
            }
        }
    }

    private func pauseAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func resumeAutoRefresh() {
        consecutiveFailures = 0
        startRefreshTimer()
        Task {
            await refresh()
        }
    }
}

struct ErrorState {
    enum ErrorType {
        case authentication
        case network
        case rateLimit
        case permission
        case server
        case unknown
    }

    let type: ErrorType
    let message: String
    let isRecoverable: Bool
    var actionHint: String?

    var icon: String {
        switch type {
        case .authentication:
            return "key.fill"
        case .network:
            return "wifi.slash"
        case .rateLimit:
            return "hourglass"
        case .permission:
            return "lock.fill"
        case .server:
            return "server.rack"
        case .unknown:
            return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch type {
        case .authentication, .permission:
            return .orange
        case .network, .server:
            return .red
        case .rateLimit:
            return .yellow
        case .unknown:
            return .red
        }
    }
}

import SwiftUI

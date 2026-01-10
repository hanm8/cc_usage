import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: UsageViewModel

    private enum Layout {
        static let windowWidth: CGFloat = 320
        static let windowHeight: CGFloat = 400
        static let avatarSize: CGFloat = 40
        static let spacing: CGFloat = 12
        static let padding: CGFloat = 12
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            HStack(alignment: .center, spacing: Layout.spacing) {
                // Avatar / Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                    
                    Text(String(viewModel.profile?.account?.displayName?.prefix(1) ?? "C"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(viewModel.profile?.account?.displayName ?? "Claude Usage")
                            .font(.headline)
                        
                        // Badge
                        if let account = viewModel.profile?.account {
                            if account.hasClaudeMax == true {
                                BadgeView(text: "MAX", color: .purple)
                            } else if account.hasClaudePro == true {
                                BadgeView(text: "PRO", color: .blue)
                            } else if viewModel.profile?.organization?.organizationType == "claude_enterprise" {
                                BadgeView(text: "ENT", color: .orange)
                            } else {
                                BadgeView(text: "FREE", color: .gray)
                            }
                        }
                    }
                    
                    if let tier = viewModel.profile?.organization?.rateLimitTier {
                        Text(tier.replacingOccurrences(of: "default_claude_", with: "").replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quit application")
                .help("Quit")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 16) {
                    if let usage = viewModel.usage {
                        // 5-Hour Limit
                        UsageCard(
                            title: "5-Hour Limit",
                            icon: "clock.arrow.circlepath",
                            utilization: usage.fiveHour?.utilization ?? 0,
                            resetsAt: usage.fiveHour?.resetsAt,
                            color: .blue
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("5-hour limit: \(Int(usage.fiveHour?.utilization ?? 0)) percent used")

                        // 7-Day Limit
                        UsageCard(
                            title: "7-Day Limit",
                            icon: "chart.bar.xaxis",
                            utilization: usage.sevenDay?.utilization ?? 0,
                            resetsAt: usage.sevenDay?.resetsAt,
                            color: .orange
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("7-day limit: \(Int(usage.sevenDay?.utilization ?? 0)) percent used")
                    } else if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                    if let errorState = viewModel.errorState {
                        ErrorView(
                            errorState: errorState,
                            onRetry: errorState.isRecoverable ? {
                                Task { await viewModel.refresh() }
                            } : nil
                        )
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Text(viewModel.profile?.organization?.name ?? "")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    Task { await viewModel.refresh() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Refresh usage data")
                .help("Refresh")
            }
            .padding(.horizontal, Layout.padding)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: Layout.windowWidth, height: Layout.windowHeight)
    }
}

struct BadgeView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

struct ErrorView: View {
    let errorState: ErrorState
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: errorState.icon)
                    .font(.title2)
                    .foregroundColor(errorState.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(errorState.message)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    if let hint = errorState.actionHint {
                        Text(hint)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            if let retry = onRetry {
                Button(action: retry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(errorState.color.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(errorState.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct UsageCard: View {
    let title: String
    let icon: String
    let utilization: Double
    let resetsAt: String?
    let color: Color

    private static let dateFormatter = ISO8601DateFormatter()

    var progressColor: Color {
        if utilization >= 90 { return .red }
        if utilization >= 75 { return .orange }
        return color
    }

    var resetTimeString: String {
        guard let resetsAt = resetsAt else { return "N/A" }
        guard let resetDate = Self.dateFormatter.date(from: resetsAt) else { return "Unknown" }
        
        let diff = resetDate.timeIntervalSinceNow
        if diff <= 0 { return "Resetting..." }
        
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Text(title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: "%.1f%%", utilization))
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
            }
            
            // Custom Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [progressColor.opacity(0.7), progressColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(geo.size.width * (utilization / 100), geo.size.width), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(resetTimeString) remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if utilization >= 80 {
                    Text("High Usage")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}

import Foundation

struct ProfileResponse: Codable {
    let account: Account?
    let organization: Organization?
}

struct Account: Codable {
    let uuid: String?
    let fullName: String?
    let displayName: String?
    let email: String?
    let hasClaudeMax: Bool?
    let hasClaudePro: Bool?
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case fullName = "full_name"
        case displayName = "display_name"
        case email
        case hasClaudeMax = "has_claude_max"
        case hasClaudePro = "has_claude_pro"
    }
}

struct Organization: Codable {
    let uuid: String?
    let name: String?
    let organizationType: String?
    let rateLimitTier: String?
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case organizationType = "organization_type"
        case rateLimitTier = "rate_limit_tier"
    }
}

import Foundation

enum WatchStatus: String, Codable {
    case idle
    case running
    case compacting
    case waitingApproval = "waiting_approval"
    case error
    case connection
    case unknown
}

struct PairLookupResponse: Decodable {
    let baseUrl: String
    let helperName: String?
}

struct PairResponse: Codable {
    let token: String
    let deviceId: String
    let deviceName: String
}

struct AgentPulseSession: Codable, Equatable {
    var baseUrl: String
    var deviceId: String
    var token: String
    var fingerprint: String
}

struct WatchSummaryResponse: Decodable {
    struct Server: Decodable {
        let helperName: String
        let version: String
        let baseUrl: String
        let remoteUrl: String?
    }

    struct RemoteAccess: Decodable {
        let enabled: Bool
        let mode: String
        let status: String
        let publicUrl: String
        let hostname: String
    }

    struct Capabilities: Decodable {
        let canOpenOnMac: Bool
        let openOnMacReason: String?
    }

    let server: Server
    let remoteAccess: RemoteAccess
    let capabilities: Capabilities
    let threads: [WatchThread]
}

struct WatchThread: Identifiable, Decodable, Hashable {
    let threadId: String
    let provider: String
    let title: String
    let workspace: String
    let workspaceKind: String?
    let status: WatchStatus
    let lastActivityAt: String
    let lastTurnSummary: String
    let pinned: Bool?
    let pinnedOrder: Int?

    var id: String { threadId }
}

struct ThreadTranscript: Decodable {
    let threadId: String
    let messages: [ChatMessage]
}

struct OlderThreadMessagesResponse: Decodable {
    let threadId: String
    let messages: [ChatMessage]
    let hasMore: Bool
}

struct ChatMessage: Identifiable, Decodable {
    let id: String
    let role: String
    let kind: String
    let text: String?
    let createdAt: String
}

struct WatchPushRequest: Encodable {
    let pushToken: String
    let bundleId: String
    let environment: String?
}

struct ThreadMessageRequest: Encodable {
    let text: String
}

struct ThreadOpenRequest: Encodable {
    let threadId: String
    let mode: String?
}

enum AgentPulseWatchError: LocalizedError {
    case missingSession
    case invalidBaseUrl
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingSession:
            return "Pair with Agent Pulse first."
        case .invalidBaseUrl:
            return "Enter a valid helper URL."
        case .server(let message):
            return message
        }
    }
}

import Foundation

final class AgentPulseClient {
    private let session: AgentPulseSession
    private let urlSession: URLSession
    private let decoder = JSONDecoder()

    init(session: AgentPulseSession, urlSession: URLSession = .shared) {
        self.session = session
        self.urlSession = urlSession
    }

    static func lookup(baseUrl: String, pin: String) async throws -> PairLookupResponse {
        guard let encodedPin = pin.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseUrl.trimmedSlash())/pair/lookup/\(encodedPin)") else {
            throw AgentPulseWatchError.invalidBaseUrl
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(PairLookupResponse.self, from: data)
    }

    static func pair(baseUrl: String, pin: String, fingerprint: String) async throws -> PairResponse {
        guard let url = URL(string: "\(baseUrl.trimmedSlash())/device/pair") else {
            throw AgentPulseWatchError.invalidBaseUrl
        }
        let body: [String: String] = [
            "pin": pin,
            "deviceName": "Apple Watch",
            "fingerprint": fingerprint
        ]
        let data = try await postJson(url: url, body: body)
        return try JSONDecoder().decode(PairResponse.self, from: data)
    }

    func summary() async throws -> WatchSummaryResponse {
        try await get("/watch/summary", as: WatchSummaryResponse.self)
    }

    func transcript(threadId: String, limit: Int = 40) async throws -> ThreadTranscript {
        guard let encoded = threadId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw AgentPulseWatchError.server("Invalid thread id.")
        }
        return try await get("/threads/\(encoded)/transcript?limit=\(limit)", as: ThreadTranscript.self)
    }

    func olderMessages(threadId: String, before messageId: String, limit: Int = 40) async throws -> OlderThreadMessagesResponse {
        guard let encodedThreadId = threadId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedMessageId = messageId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw AgentPulseWatchError.server("Invalid thread or message id.")
        }
        return try await get(
            "/threads/\(encodedThreadId)/transcript/older?before=\(encodedMessageId)&limit=\(limit)",
            as: OlderThreadMessagesResponse.self
        )
    }

    func sendReply(threadId: String, text: String) async throws -> ThreadMessageResponse {
        guard let encoded = threadId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw AgentPulseWatchError.server("Invalid thread id.")
        }
        let data = try await request(
            path: "/threads/\(encoded)/messages",
            method: "POST",
            body: ThreadMessageRequest(text: text),
            watchClient: true
        )
        return try decoder.decode(ThreadMessageResponse.self, from: data)
    }

    func stop(threadId: String) async throws {
        guard let encoded = threadId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw AgentPulseWatchError.server("Invalid thread id.")
        }
        _ = try await request(path: "/threads/\(encoded)/stop", method: "POST", body: EmptyBody())
    }

    func openOnMac(threadId: String) async throws {
        _ = try await request(
            path: "/thread/open",
            method: "POST",
            body: ThreadOpenRequest(threadId: threadId, mode: "open")
        )
    }

    func registerPushToken(_ token: String) async throws {
        _ = try await request(
            path: "/devices/watch-push",
            method: "POST",
            body: WatchPushRequest(
                pushToken: token,
                bundleId: "com.paulfecto.AgentPulse.watchkitapp",
                environment: "sandbox"
            )
        )
    }

    func deletePushToken() async throws {
        _ = try await request(path: "/devices/watch-push", method: "DELETE", body: EmptyBody())
    }

    private func get<Value: Decodable>(_ path: String, as type: Value.Type) async throws -> Value {
        let data = try await request(path: path, method: "GET", body: Optional<EmptyBody>.none)
        return try decoder.decode(type, from: data)
    }

    private func request<Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        watchClient: Bool = false
    ) async throws -> Data {
        guard let url = URL(string: "\(session.baseUrl.trimmedSlash())\(path)") else {
            throw AgentPulseWatchError.invalidBaseUrl
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(session.token)", forHTTPHeaderField: "Authorization")
        request.setValue(session.deviceId, forHTTPHeaderField: "X-Agent-Pulse-Device-Id")
        request.setValue(session.fingerprint, forHTTPHeaderField: "X-Agent-Pulse-Fingerprint")
        if watchClient {
            request.setValue("watch", forHTTPHeaderField: "X-Agent-Pulse-Client")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        let (data, response) = try await urlSession.data(for: request)
        try Self.validate(response: response, data: data)
        return data
    }

    private static func postJson<Body: Encodable>(url: URL, body: Body) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return data
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if responseLooksLikeHtml(http, data: data) {
            throw AgentPulseWatchError.server(
                "Agent Pulse returned a web page instead of API data. The public route is pointing at the wrong app."
            )
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ServerError.self, from: data).error) ?? "Agent Pulse returned \(http.statusCode)."
            throw AgentPulseWatchError.server(message)
        }
    }

    private static func responseLooksLikeHtml(_ response: HTTPURLResponse, data: Data) -> Bool {
        let contentType = response.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
        if contentType.contains("text/html") {
            return true
        }
        guard let prefix = String(data: data.prefix(512), encoding: .utf8)?.lowercased() else {
            return false
        }
        return prefix.contains("<!doctype html") ||
            prefix.contains("<html") ||
            prefix.contains("/project-manager/") ||
            prefix.contains("<title>dope-ai</title>")
    }
}

struct EmptyBody: Encodable {}

private struct ServerError: Decodable {
    let error: String
}

private extension String {
    func trimmedSlash() -> String {
        hasSuffix("/") ? String(dropLast()) : self
    }
}

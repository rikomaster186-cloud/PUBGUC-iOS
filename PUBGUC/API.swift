import Foundation
import WebKit

enum APIError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self { case .message(let text): return text }
    }
}

enum API {
    static let base = URL(string: "https://x.tekdemonx.workers.dev")!

    static func login(username: String, password: String) async throws {
        let body: [String: Any] = [
            "username": username,
            "password": password
        ]
        try await post(path: "/api/auth/login", body: body)
    }

    static func register(username: String, password: String, age: Int, pubgId: String, gender: String, kd: String) async throws {
        let body: [String: Any] = [
            "username": username,
            "password": password,
            "age": age,
            "pubgId": pubgId,
            "gender": gender,
            "kd": kd,
            "tiktokFollowed": true,
            "youtubeSubscribed": true
        ]
        try await post(path: "/api/auth/register", body: body)
    }

    private static func post(path: String, body: [String: Any]) async throws {
        let url = URL(string: path, relativeTo: base)!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.message("Invalid response")
        }

        if let fields = http.allHeaderFields as? [String: String],
           let url = response.url {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
            let store = WKWebsiteDataStore.default().httpCookieStore
            for cookie in cookies {
                await withCheckedContinuation { cont in
                    store.setCookie(cookie) { cont.resume() }
                }
            }
        }

        guard (200...299).contains(http.statusCode) else {
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let msg = (obj["error"] as? String) ?? (obj["message"] as? String) ?? "Request failed"
                throw APIError.message(msg)
            }
            throw APIError.message("Request failed")
        }
    }
}

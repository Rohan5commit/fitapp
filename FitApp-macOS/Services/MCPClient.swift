import Foundation

enum MCPClientError: LocalizedError {
    case invalidURL
    case transportError(Error)
    case requestFailed(statusCode: Int, body: String)
    case decodeError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid MCP server URL."
        case let .transportError(error):
            return "Network error: \(error.localizedDescription)"
        case let .requestFailed(statusCode, body):
            return "MCP request failed (\(statusCode)): \(body)"
        case let .decodeError(error):
            return "Could not decode server response: \(error.localizedDescription)"
        }
    }
}

final class MCPClient {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    func analyzeTrends(baseURL: URL, request: AnalyzeTrendsRequest) async throws -> AnalyzeTrendsResponse {
        try await post(baseURL: baseURL, path: "/analyze-trends", request: request)
    }

    func analyzeTrends(
        baseURL: URL,
        request: AnalyzeTrendsRequest,
        headers: [String: String]
    ) async throws -> AnalyzeTrendsResponse {
        try await post(baseURL: baseURL, path: "/analyze-trends", request: request, headers: headers)
    }

    func generatePlan(baseURL: URL, request: GeneratePlanRequest) async throws -> GeneratePlanResponse {
        try await post(baseURL: baseURL, path: "/generate-plan", request: request)
    }

    func generatePlan(
        baseURL: URL,
        request: GeneratePlanRequest,
        headers: [String: String]
    ) async throws -> GeneratePlanResponse {
        try await post(baseURL: baseURL, path: "/generate-plan", request: request, headers: headers)
    }

    func recommendAdjustments(
        baseURL: URL,
        request: RecommendAdjustmentsRequest
    ) async throws -> RecommendAdjustmentsResponse {
        try await post(baseURL: baseURL, path: "/recommend-adjustments", request: request)
    }

    func recommendAdjustments(
        baseURL: URL,
        request: RecommendAdjustmentsRequest,
        headers: [String: String]
    ) async throws -> RecommendAdjustmentsResponse {
        try await post(baseURL: baseURL, path: "/recommend-adjustments", request: request, headers: headers)
    }

    private func post<T: Encodable, U: Decodable>(
        baseURL: URL,
        path: String,
        request: T,
        headers: [String: String] = [:]
    ) async throws -> U {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw MCPClientError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 30
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (name, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }
        urlRequest.httpBody = try encoder.encode(request)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MCPClientError.requestFailed(statusCode: -1, body: "Invalid HTTP response")
            }

            guard 200 ..< 300 ~= httpResponse.statusCode else {
                let body = String(data: data, encoding: .utf8) ?? "No response body"
                throw MCPClientError.requestFailed(statusCode: httpResponse.statusCode, body: body)
            }

            do {
                return try decoder.decode(U.self, from: data)
            } catch {
                throw MCPClientError.decodeError(error)
            }
        } catch let error as MCPClientError {
            throw error
        } catch {
            throw MCPClientError.transportError(error)
        }
    }
}

protocol APIClientProtocol: Sendable {
    func send<Response: Decodable & Sendable>(_ endpoint: any Endpoint, decodingTo type: Response.Type) async throws -> Response
}

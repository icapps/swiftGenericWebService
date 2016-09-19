public enum Method: String {
    case GET, POST, PUT, DELETE, PATCH
}

open class Call {
    open let path: String
    open let method: Method
    open var rootNode: String?

    /// Initializes Call to retreive object(s) from the server.
    /// parameter rootNode: used to extract JSON in method `rootNode(from:)`.
    public init(path: String, method: Method = .GET, rootNode: String? = nil) {
        self.path = path
        self.method = method
        self.rootNode = rootNode
    }

    open func request(withConfiguration configuration: Configuration) -> URLRequest? {
        var request = URLRequest(url: URL(string: "\(configuration.baseURL)/\(path)")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0)
        request.httpMethod = method.rawValue

        return request
    }

    /// Use to begin paring at the correct `rootnode`.
    /// Override if you want different behaviour then: 
    /// `{"rootNode": <Any Node>}` `<Any Node> is returned when `rootNode` is set.
    open func rootNode(from json: Any) -> JsonNode {
        let json = extactNodeIfNeeded(from: json)

        if let jsonArray = json as? [Any] {
            return .nodeArray(jsonArray)
        }else if let json = json as? [String: Any] {
            return .nodeObject(json)
        }else {
            return .nodeNotFound(json: json)
        }
    }

    private func extactNodeIfNeeded(from json: Any?) -> Any? {
        guard  let rootNode = rootNode, let rootedJson = json as? [String: Any] else {
            return json
        }

        return rootedJson[rootNode]
    }

}

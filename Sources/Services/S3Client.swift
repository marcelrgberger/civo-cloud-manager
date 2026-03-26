import Foundation
import CryptoKit

final class S3Client: Sendable {
    let endpoint: String
    let accessKey: String
    let secretKey: String
    let region: String

    init(endpoint: String, accessKey: String, secretKey: String, region: String = "fra1") {
        self.endpoint = endpoint.hasPrefix("https://") ? endpoint : "https://\(endpoint)"
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.region = region
    }

    // MARK: - S3 Operations

    func listObjects(bucket: String, prefix: String = "", delimiter: String = "/") async throws -> S3ListResult {
        var queryParams = [
            ("delimiter", delimiter),
            ("list-type", "2")
        ]
        if !prefix.isEmpty {
            queryParams.append(("prefix", prefix))
        }
        let query = queryParams
            .sorted { $0.0 < $1.0 }
            .map { "\(uriEncode($0.0))=\(uriEncode($0.1))" }
            .joined(separator: "&")
        let data = try await request(method: "GET", bucket: bucket, path: "/", query: query)
        return try S3XMLParser.parseListResult(data)
    }

    func listAllObjects(bucket: String, prefix: String) async throws -> [S3Object] {
        var allObjects: [S3Object] = []
        var continuationToken: String?

        repeat {
            var queryParams = [
                ("list-type", "2"),
                ("prefix", prefix)
            ]
            if let token = continuationToken {
                queryParams.append(("continuation-token", token))
            }
            let query = queryParams
                .sorted { $0.0 < $1.0 }
                .map { "\(uriEncode($0.0))=\(uriEncode($0.1))" }
                .joined(separator: "&")
            let data = try await request(method: "GET", bucket: bucket, path: "/", query: query)
            let parsed = try S3XMLParser.parseListResult(data)
            allObjects.append(contentsOf: parsed.objects)
            continuationToken = parsed.nextContinuationToken
        } while continuationToken != nil

        return allObjects
    }

    func downloadObject(bucket: String, key: String) async throws -> Data {
        return try await request(method: "GET", bucket: bucket, path: "/\(key)")
    }

    func headObject(bucket: String, key: String) async throws -> (size: Int, contentType: String) {
        let path = "/\(key)"
        let (_, response) = try await rawRequest(method: "HEAD", bucket: bucket, path: path)
        let size = Int(response.value(forHTTPHeaderField: "Content-Length") ?? "0") ?? 0
        let contentType = response.value(forHTTPHeaderField: "Content-Type") ?? "application/octet-stream"
        return (size, contentType)
    }

    func uploadObject(bucket: String, key: String, data: Data, contentType: String = "application/octet-stream") async throws {
        let path = "/\(key)"
        let _ = try await rawRequest(method: "PUT", bucket: bucket, path: path, body: data, contentType: contentType)
    }

    func deleteObject(bucket: String, key: String) async throws {
        let path = "/\(key)"
        let _ = try await rawRequest(method: "DELETE", bucket: bucket, path: path)
    }

    func deleteObjects(bucket: String, keys: [String]) async throws {
        for key in keys {
            try await deleteObject(bucket: bucket, key: key)
        }
    }

    // MARK: - HTTP with AWS Signature V4

    private func request(method: String, bucket: String, path: String, query: String = "") async throws -> Data {
        let (data, _) = try await rawRequest(method: method, bucket: bucket, path: path, query: query)
        return data
    }

    private func rawRequest(method: String, bucket: String, path: String, query: String = "", body: Data? = nil, contentType: String? = nil) async throws -> (Data, HTTPURLResponse) {
        let host = endpoint.replacingOccurrences(of: "https://", with: "")
        let rawPath = "/\(bucket)\(path)"
        // Encode path for the HTTP URL (preserve /)
        let encodedPath = rawPath.components(separatedBy: "/")
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? $0 }
            .joined(separator: "/")
        let urlString = "https://\(host)\(encodedPath)\(query.isEmpty ? "" : "?\(query)")"
        guard let url = URL(string: urlString) else {
            throw S3Error.invalidURL(urlString)
        }

        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let amzDate = dateFormatter.string(from: now)

        dateFormatter.dateFormat = "yyyyMMdd"
        let dateStamp = dateFormatter.string(from: now)

        let payload = body ?? Data()
        let payloadHash = sha256(payload)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(host, forHTTPHeaderField: "Host")
        request.setValue(amzDate, forHTTPHeaderField: "x-amz-date")
        request.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")
        request.timeoutInterval = 30

        if let body {
            request.httpBody = body
            request.setValue(contentType ?? "application/octet-stream", forHTTPHeaderField: "Content-Type")
            request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        }

        // Canonical URI: SigV4-encode each path segment
        let canonicalURI = rawPath.components(separatedBy: "/")
            .map { uriEncode($0) }
            .joined(separator: "/")

        // Canonical query string (already sorted and encoded by caller)
        let canonicalQuery = query

        // AWS Signature V4
        let signedHeaders: String
        let canonicalHeaders: String
        if body != nil {
            signedHeaders = "content-length;content-type;host;x-amz-content-sha256;x-amz-date"
            canonicalHeaders = "content-length:\(payload.count)\ncontent-type:\(contentType ?? "application/octet-stream")\nhost:\(host)\nx-amz-content-sha256:\(payloadHash)\nx-amz-date:\(amzDate)\n"
        } else {
            signedHeaders = "host;x-amz-content-sha256;x-amz-date"
            canonicalHeaders = "host:\(host)\nx-amz-content-sha256:\(payloadHash)\nx-amz-date:\(amzDate)\n"
        }
        let canonicalRequest = "\(method)\n\(canonicalURI)\n\(canonicalQuery)\n\(canonicalHeaders)\n\(signedHeaders)\n\(payloadHash)"

        let scope = "\(dateStamp)/\(region)/s3/aws4_request"
        let stringToSign = "AWS4-HMAC-SHA256\n\(amzDate)\n\(scope)\n\(sha256(canonicalRequest.data(using: .utf8)!))"

        let signingKey = getSignatureKey(secretKey, dateStamp: dateStamp, regionName: region, serviceName: "s3")
        let signature = hmacSHA256(key: signingKey, data: stringToSign.data(using: .utf8)!).map { String(format: "%02x", $0) }.joined()

        request.setValue("AWS4-HMAC-SHA256 Credential=\(accessKey)/\(scope), SignedHeaders=\(signedHeaders), Signature=\(signature)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw S3Error.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw S3Error.httpError(http.statusCode, msg)
        }
        return (data, http)
    }

    // MARK: - URI Encoding (AWS SigV4 compliant)

    private func uriEncode(_ string: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }

    // MARK: - Crypto helpers

    private func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func hmacSHA256(key: Data, data: Data) -> Data {
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: SymmetricKey(data: key))
        return Data(hmac)
    }

    private func getSignatureKey(_ key: String, dateStamp: String, regionName: String, serviceName: String) -> Data {
        let kDate = hmacSHA256(key: "AWS4\(key)".data(using: .utf8)!, data: dateStamp.data(using: .utf8)!)
        let kRegion = hmacSHA256(key: kDate, data: regionName.data(using: .utf8)!)
        let kService = hmacSHA256(key: kRegion, data: serviceName.data(using: .utf8)!)
        return hmacSHA256(key: kService, data: "aws4_request".data(using: .utf8)!)
    }
}

// MARK: - Models

struct S3ListResult: Sendable {
    let objects: [S3Object]
    let commonPrefixes: [String]
    let nextContinuationToken: String?
}

struct S3Object: Identifiable, Sendable {
    let key: String
    let size: Int
    let lastModified: String

    var id: String { key }

    var name: String {
        key.components(separatedBy: "/").last ?? key
    }

    var sizeDisplay: String {
        if size < 1024 { return "\(size) B" }
        if size < 1024 * 1024 { return "\(size / 1024) KB" }
        if size < 1024 * 1024 * 1024 { return "\(size / (1024 * 1024)) MB" }
        return String(format: "%.1f GB", Double(size) / (1024 * 1024 * 1024))
    }
}

// MARK: - XML Parser

enum S3XMLParser {
    static func parseListResult(_ data: Data) throws -> S3ListResult {
        guard let xml = String(data: data, encoding: .utf8) else {
            throw S3Error.invalidResponse
        }

        var objects: [S3Object] = []
        var prefixes: [String] = []

        // Parse <Contents> elements
        let contentPattern = "<Contents>([\\s\\S]*?)</Contents>"
        let contentRegex = try NSRegularExpression(pattern: contentPattern)
        let matches = contentRegex.matches(in: xml, range: NSRange(xml.startIndex..., in: xml))
        for match in matches {
            let content = String(xml[Range(match.range(at: 1), in: xml)!])
            let key = extractXMLValue(content, tag: "Key") ?? ""
            let size = Int(extractXMLValue(content, tag: "Size") ?? "0") ?? 0
            let lastModified = extractXMLValue(content, tag: "LastModified") ?? ""
            if !key.hasSuffix("/") {
                objects.append(S3Object(key: key, size: size, lastModified: lastModified))
            }
        }

        // Parse <CommonPrefixes><Prefix>
        let prefixPattern = "<CommonPrefixes>\\s*<Prefix>(.*?)</Prefix>"
        let prefixRegex = try NSRegularExpression(pattern: prefixPattern)
        let prefixMatches = prefixRegex.matches(in: xml, range: NSRange(xml.startIndex..., in: xml))
        for match in prefixMatches {
            let prefix = String(xml[Range(match.range(at: 1), in: xml)!])
            prefixes.append(prefix)
        }

        // Parse pagination token
        let nextToken = extractXMLValue(xml, tag: "NextContinuationToken")

        return S3ListResult(objects: objects, commonPrefixes: prefixes, nextContinuationToken: nextToken)
    }

    private static func extractXMLValue(_ xml: String, tag: String) -> String? {
        let pattern = "<\(tag)>(.*?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
              let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
              let range = Range(match.range(at: 1), in: xml) else { return nil }
        return String(xml[range])
    }
}

// MARK: - Errors

enum S3Error: LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url): return "Invalid S3 URL: \(url)"
        case .invalidResponse: return "Invalid S3 response"
        case .httpError(let code, let msg): return "S3 error (\(code)): \(msg)"
        }
    }
}

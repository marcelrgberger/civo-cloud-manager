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
        var query = "delimiter=\(delimiter)&list-type=2"
        if !prefix.isEmpty {
            query += "&prefix=\(prefix.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? prefix)"
        }
        let data = try await request(method: "GET", bucket: bucket, path: "/", query: query)
        return try S3XMLParser.parseListResult(data)
    }

    func downloadObject(bucket: String, key: String) async throws -> Data {
        let path = "/\(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key)"
        return try await request(method: "GET", bucket: bucket, path: path)
    }

    func headObject(bucket: String, key: String) async throws -> (size: Int, contentType: String) {
        let path = "/\(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key)"
        let (_, response) = try await rawRequest(method: "HEAD", bucket: bucket, path: path)
        let size = Int(response.value(forHTTPHeaderField: "Content-Length") ?? "0") ?? 0
        let contentType = response.value(forHTTPHeaderField: "Content-Type") ?? "application/octet-stream"
        return (size, contentType)
    }

    // MARK: - HTTP with AWS Signature V4

    private func request(method: String, bucket: String, path: String, query: String = "") async throws -> Data {
        let (data, _) = try await rawRequest(method: method, bucket: bucket, path: path, query: query)
        return data
    }

    private func rawRequest(method: String, bucket: String, path: String, query: String = "") async throws -> (Data, HTTPURLResponse) {
        let host = endpoint.replacingOccurrences(of: "https://", with: "")
        let fullPath = "/\(bucket)\(path)"
        let urlString = "https://\(host)\(fullPath)\(query.isEmpty ? "" : "?\(query)")"
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

        let payloadHash = sha256(Data())

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(host, forHTTPHeaderField: "Host")
        request.setValue(amzDate, forHTTPHeaderField: "x-amz-date")
        request.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")
        request.timeoutInterval = 30

        // Canonical query string: params sorted by key
        let canonicalQuery = query.components(separatedBy: "&")
            .filter { !$0.isEmpty }
            .sorted()
            .joined(separator: "&")

        // AWS Signature V4
        let signedHeaders = "host;x-amz-content-sha256;x-amz-date"
        let canonicalHeaders = "host:\(host)\nx-amz-content-sha256:\(payloadHash)\nx-amz-date:\(amzDate)\n"
        let canonicalRequest = "\(method)\n\(fullPath)\n\(canonicalQuery)\n\(canonicalHeaders)\n\(signedHeaders)\n\(payloadHash)"

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

        return S3ListResult(objects: objects, commonPrefixes: prefixes)
    }

    private static func extractXMLValue(_ xml: String, tag: String) -> String? {
        let pattern = "<\(tag)>(.*?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern),
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

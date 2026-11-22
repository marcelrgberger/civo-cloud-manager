import Foundation

final class CivoSizeService: Sendable {
    private let api = CivoAPIClient.shared

    /// Sizes offered in `region`, or in the Settings region when nil. Civo lists different sizes per region.
    func listSizes(region: String? = nil) async throws -> [CivoSize] {
        try await api.getArray(path: "/sizes", queryItems: region.map { [URLQueryItem(name: "region", value: $0)] })
    }

    func listDiskImages() async throws -> [CivoDiskImage] {
        try await api.getArray(path: "/disk_images")
    }
}

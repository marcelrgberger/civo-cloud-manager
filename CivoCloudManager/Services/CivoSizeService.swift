import Foundation

final class CivoSizeService: Sendable {
    private let api = CivoAPIClient.shared

    func listSizes() async throws -> [CivoSize] {
        try await api.getArray(path: "/sizes")
    }

    func listDiskImages() async throws -> [CivoDiskImage] {
        try await api.getArray(path: "/disk_images")
    }
}

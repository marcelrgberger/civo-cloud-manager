#if DEBUG
import Foundation

extension KeychainClient {
    /// An always empty keychain for demo mode: nothing is read from or written to the real one.
    static var demo: KeychainClient {
        KeychainClient(
            add: { _ in errSecSuccess },
            update: { _, _ in errSecItemNotFound },
            copyMatching: { _ in (errSecItemNotFound, nil) },
            delete: { _ in errSecItemNotFound }
        )
    }
}
#endif

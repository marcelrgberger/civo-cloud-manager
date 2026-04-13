import os

enum Log {
    private static let logger = os.Logger(subsystem: "de.berger-rosenstock.CivoCloudManager", category: "general")

    static func info(_ message: String) {
        logger.info("\(message, privacy: .private)")
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    static func debug(_ message: String) {
        logger.debug("\(message, privacy: .private)")
    }

    static func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }
}

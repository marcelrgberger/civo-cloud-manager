import Foundation

enum ProcessRunnerError: LocalizedError {
    case timeout(seconds: Int)
    case noResult
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .timeout(let seconds):
            return "Process timed out after \(seconds)s"
        case .noResult:
            return "Process completed without result"
        case .executionFailed(let message):
            return message
        }
    }
}

final class ProcessRunner: @unchecked Sendable {
    struct Result: Sendable {
        let stdout: String
        let stderr: String
        let exitCode: Int32
    }

    /// Run a process fully off the cooperative thread pool using a dedicated Thread.
    func run(_ executable: String, arguments: [String], timeout: TimeInterval = 120) async throws -> Result {
        let sem = DispatchSemaphore(value: 0)
        var processResult: Result?
        var processError: Error?

        let thread = Thread {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments

            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
            process.environment = env

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            do {
                try process.run()
            } catch {
                processError = error
                sem.signal()
                return
            }

            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            let stdout = String(data: stdoutData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let stderr = String(data: stderrData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            processResult = Result(stdout: stdout, stderr: stderr, exitCode: process.terminationStatus)
            sem.signal()
        }
        thread.qualityOfService = .userInitiated
        thread.start()

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let waitResult = sem.wait(timeout: .now() + timeout)
                if waitResult == .timedOut {
                    continuation.resume(throwing: ProcessRunnerError.timeout(seconds: Int(timeout)))
                } else if let error = processError {
                    continuation.resume(throwing: error)
                } else if let result = processResult {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: ProcessRunnerError.noResult)
                }
            }
        }
    }

    @discardableResult
    func runCivo(_ arguments: [String], timeout: TimeInterval = 60) async throws -> String {
        let civoPath = findExecutable("civo")
        let result = try await run(civoPath, arguments: arguments, timeout: timeout)
        if result.exitCode != 0 {
            throw ProcessRunnerError.executionFailed("civo CLI error: \(result.stderr)")
        }
        return result.stdout
    }

    func findExecutable(_ name: String) -> String {
        for path in ["/opt/homebrew/bin/\(name)", "/usr/local/bin/\(name)", "/usr/bin/\(name)"] {
            if FileManager.default.isExecutableFile(atPath: path) { return path }
        }
        return "/usr/bin/\(name)"
    }
}

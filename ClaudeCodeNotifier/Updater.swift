import SwiftUI

@Observable
final class Updater {
    static let shared = Updater()

    private(set) var state: UpdateState = .idle
    private(set) var targetRelease: Release?
    private(set) var progress: Double = 0

    private var checkTask: Task<(), Never>?

    enum UpdateState: Equatable {
        case idle
        case checking
        case available
        case downloading
        case installing
        case upToDate
        case failed(String)

        static func == (lhs: UpdateState, rhs: UpdateState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.checking, .checking), (.available, .available),
                 (.downloading, .downloading), (.installing, .installing), (.upToDate, .upToDate):
                true
            case (.failed(let a), .failed(let b)):
                a == b
            default:
                false
            }
        }
    }

    private init() {}

    private static let repoOwner = "andrewii23"
    private static let repoName = "claude-code-notifier"

    func checkForUpdates() async {
        state = .checking
        targetRelease = nil
        progress = 0

        guard let url = URL(string: "https://api.github.com/repos/\(Self.repoOwner)/\(Self.repoName)/releases/latest") else {
            state = .failed("Invalid URL")
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let http = response as? HTTPURLResponse, http.statusCode == 404 {
                state = .upToDate
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let release = try decoder.decode(Release.self, from: data)

            let currentVersion = Bundle.main.appVersion ?? "0.0.0"
            let remoteVersion = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName
            if remoteVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                targetRelease = release
                state = .available
            } else {
                state = .upToDate
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func installUpdate() async {
        guard let release = targetRelease, let asset = release.assets.first else { return }

        state = .downloading
        progress = 0

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(asset.name)_\(release.tagName)")

        do {
            let (fileURL, _) = try await URLSession.shared.download(from: asset.browserDownloadURL)
            try FileManager.default.moveItem(at: fileURL, to: tempURL)
        } catch {
            state = .failed("Download failed: \(error.localizedDescription)")
            return
        }

        progress = 0.5
        state = .installing

        do {
            try await unzipAndReplace(zipPath: tempURL.path)
            try? FileManager.default.removeItem(at: tempURL)
            progress = 1.0
            relaunch()
        } catch {
            state = .failed("Install failed: \(error.localizedDescription)")
        }
    }

    private func unzipAndReplace(zipPath: String) async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-xk", zipPath, tempDir.path]
        try process.run()
        process.waitUntilExit()

        let contents = try fm.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        guard let newApp = contents.first(where: { $0.pathExtension == "app" }) else {
            try fm.removeItem(at: tempDir)
            throw UpdateError.noAppBundle
        }

        _ = try fm.replaceItemAt(Bundle.main.bundleURL, withItemAt: newApp, backupItemName: nil, options: [.usingNewMetadataOnly])
        try fm.removeItem(at: tempDir)
    }

    private func relaunch() {
        let url = Bundle.main.bundleURL
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [url.path]
        try? task.run()
        NSApp.terminate(nil)
    }

    enum UpdateError: LocalizedError {
        case noAppBundle

        var errorDescription: String? {
            switch self {
            case .noAppBundle: "No app bundle found in update"
            }
        }
    }
}

struct Release: Codable {
    var id: Int
    var tagName: String
    var name: String
    var body: String
    var assets: [Asset]
    var prerelease: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name, body, assets, prerelease
    }

    struct Asset: Codable {
        var name: String
        var browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }
}

extension Bundle {
    var appName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "App"
    }

    var appVersion: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var appBuild: String? {
        infoDictionary?["CFBundleVersion"] as? String
    }
}

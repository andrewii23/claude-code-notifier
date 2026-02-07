import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case notification
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .notification: "Notification"
        case .about: "About"
        }
    }

    var icon: String {
        switch self {
        case .general: "gear"
        case .notification: "bell.fill"
        case .about: "info.circle.fill"
        }
    }

    static let iconColor = Color.accentOrange

    @ViewBuilder
    func view() -> some View {
        switch self {
        case .general: GeneralSettingsView()
        case .notification: NotificationSettingsView()
        case .about: AboutView()
        }
    }

    static let settingsTabs: [SettingsTab] = [.general, .notification]
    static let appTabs: [SettingsTab] = [.about]
}

extension Color {
    static let accentOrange = Color(red: 0.79, green: 0.49, blue: 0.37)
}

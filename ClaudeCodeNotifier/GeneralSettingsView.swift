import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("hideMenuBarIcon") private var hideMenuBarIcon = false
    @AppStorage("appearance") private var appearance = AppAppearance.auto.rawValue

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .tint(Color.accentOrange)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }

                Toggle("Hide menu bar icon", isOn: $hideMenuBarIcon)
                    .tint(Color.accentOrange)
                    .onChange(of: hideMenuBarIcon) { _, hidden in
                        if hidden {
                            NSApp.setActivationPolicy(.regular)
                            NSApp.activate()
                        }
                    }

                Picker("Appearance", selection: $appearance) {
                    ForEach(AppAppearance.allCases, id: \.rawValue) { option in
                        Text(option.label).tag(option.rawValue)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

enum AppAppearance: String, CaseIterable {
    case auto
    case light
    case dark

    var label: String {
        switch self {
        case .auto: "Auto"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .auto: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

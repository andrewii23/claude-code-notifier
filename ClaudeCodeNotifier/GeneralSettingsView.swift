import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("hideMenuBarIcon") private var hideMenuBarIcon = false
    @AppStorage("appearance") private var appearance = AppAppearance.auto.rawValue

    var body: some View {
        SettingsSection {
            SettingsToggleRow(title: "Launch at login", isOn: $launchAtLogin)
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

            SettingsToggleRow(title: "Hide menu bar icon", isOn: $hideMenuBarIcon)
                .onChange(of: hideMenuBarIcon) { _, hidden in
                    if hidden {
                        NSApp.setActivationPolicy(.regular)
                        NSApp.activate()
                    }
                }

            SettingsPickerRow(
                title: "Appearance",
                selection: $appearance,
                options: AppAppearance.allCases.map { ($0.rawValue, $0.label) }
            )
        }
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

// MARK: - Reusable Components

struct SettingsSection<Content: View>: View {
    let header: String?
    @ViewBuilder let content: Content

    init(_ header: String? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let header {
                Text(header)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
            }

            _SettingsSectionContent {
                content
            }
        }
    }
}

struct _SettingsSectionContent<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            _VariadicView.Tree(_SectionLayout()) {
                content
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quinary)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }
}

struct _SectionLayout: _VariadicView_MultiViewRoot {
    func body(children: _VariadicView.Children) -> some View {
        let last = children.last?.id

        VStack(spacing: 0) {
            ForEach(children) { child in
                child
                    .padding(4)
                    .padding(.top, child.id == children.first?.id ? 1 : 0)
                    .padding(.bottom, child.id == last ? 1 : 0)
                    .padding(.horizontal, 1)

                if child.id != last {
                    Divider()
                        .padding(.horizontal, 1)
                }
            }
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .padding(.vertical, 4)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(Color.accentOrange)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 30)
    }
}

struct SettingsTextFieldRow: View {
    let placeholder: String
    @Binding var text: String
    var label: String?

    var body: some View {
        HStack {
            if let label {
                Text(label)
                    .padding(.vertical, 4)
                Spacer()
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 200)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(minHeight: 30)
    }
}

struct SettingsInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(minHeight: 30)
    }
}

struct SettingsPickerRow: View {
    let title: String
    @Binding var selection: String
    let options: [(value: String, label: String)]

    var body: some View {
        HStack {
            Text(title)
                .padding(.vertical, 4)
            Spacer()
            Picker(title, selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .labelsHidden()
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 30)
    }
}

import SwiftUI

struct SettingsSectionView<Content: View>: View {
    let title: LocalizedStringResource
    let footer: LocalizedStringResource?
    @ViewBuilder let content: Content

    init(_ title: LocalizedStringResource, footer: LocalizedStringResource? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        Section {
            content
        } header: {
            Text(title)
        } footer: {
            if let footer {
                Text(footer)
            }
        }
    }
}

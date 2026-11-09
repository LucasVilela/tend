import SwiftUI

struct RootView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            Text("[APP NAME]").textStyle(Theme.Font.title).foregroundStyle(Theme.textPrimary)
        }
    }
}

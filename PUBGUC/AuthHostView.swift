import SwiftUI

struct AuthHostView: View {
    let onLoggedIn: () -> Void
    let onBrowse: () -> Void

    var body: some View {
        AuthView()
            .onAppear {
                AuthBridge.shared.onLoggedIn = onLoggedIn
                AuthBridge.shared.onBrowse = onBrowse
            }
    }
}

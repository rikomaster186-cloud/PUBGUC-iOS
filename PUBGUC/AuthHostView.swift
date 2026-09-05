import SwiftUI

struct AuthHostView: View {
    let onLoggedIn: () -> Void
    let onBrowse: () -> Void

    var body: some View {
        AuthView(onLoggedIn: onLoggedIn, onBrowse: onBrowse)
    }
}

import SwiftUI
import WebKit

struct RootView: View {
    @AppStorage("pubguc_app_logged_in") private var loggedIn = false
    @State private var showWeb = false
    @State private var browseOnly = false

    var body: some View {
        Group {
            if showWeb {
                WebContainerView(appMode: !browseOnly, onLogout: {
                    loggedIn = false
                    showWeb = false
                    browseOnly = false
                })
            } else if loggedIn {
                WebContainerView(appMode: true, onLogout: {
                    loggedIn = false
                    showWeb = false
                })
            } else {
                AuthHostView(
                    onLoggedIn: {
                        loggedIn = true
                        showWeb = true
                        browseOnly = false
                    },
                    onBrowse: {
                        showWeb = true
                        browseOnly = true
                    }
                )
            }
        }
    }
}

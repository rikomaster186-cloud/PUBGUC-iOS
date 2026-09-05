import SwiftUI
import WebKit

struct WebContainerView: UIViewRepresentable {
    let appMode: Bool
    let onLogout: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(appMode: appMode, onLogout: onLogout)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true

        let userContent = WKUserContentController()
        userContent.add(context.coordinator, name: "pubguc")

        if appMode {
            let js = """
            (function(){
              function hideAuth(){
                const sels = [
                  'a[href*="login"]','a[href*="register"]',
                  '[data-action="login"]','[data-action="register"]',
                  '.login-btn','.register-btn','#loginBtn','#registerBtn'
                ];
                sels.forEach(s => document.querySelectorAll(s).forEach(el => el.style.display='none'));
              }
              hideAuth();
              new MutationObserver(hideAuth).observe(document.documentElement,{subtree:true,childList:true});

              const oldFetch = window.fetch;
              window.fetch = async function(){
                const r = await oldFetch.apply(this, arguments);
                try {
                  const u = String(arguments[0]);
                  if (u.includes('/api/auth/logout') && r.ok) {
                    window.webkit.messageHandlers.pubguc.postMessage('logout');
                  }
                } catch(e){}
                return r;
              };
            })();
            """
            userContent.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false))
        }

        config.userContentController = userContent

        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.allowsBackForwardNavigationGestures = true
        if let url = URL(string: "https://x.tekdemonx.workers.dev/") {
            web.load(URLRequest(url: url))
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let appMode: Bool
        let onLogout: () -> Void

        init(appMode: Bool, onLogout: @escaping () -> Void) {
            self.appMode = appMode
            self.onLogout = onLogout
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "pubguc", (message.body as? String) == "logout" {
                UserDefaults.standard.set(false, forKey: "pubguc_app_logged_in")
                DispatchQueue.main.async { self.onLogout() }
            }
        }
    }
}

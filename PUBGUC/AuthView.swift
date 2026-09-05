import SwiftUI
import WebKit

struct AuthView: View {
    @State private var language = "TR"
    @State private var mode: AuthMode? = nil
    @State private var message = ""

    enum AuthMode { case login, register }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.05)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    Button("TR") { language = "TR" }
                        .buttonStyle(LangButtonStyle(active: language == "TR"))
                    Button("EN") { language = "EN" }
                        .buttonStyle(LangButtonStyle(active: language == "EN"))
                }

                Spacer()

                Text("PUBGUC")
                    .font(.system(size: 48, weight: .black))
                    .foregroundStyle(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: .green.opacity(0.55), radius: 14)

                Text("by TEKDEMONX")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))

                Text(language == "TR" ? "UC kazanmak için giriş yap" : "Login to earn UC")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 8)

                if let mode = mode {
                    AuthForm(mode: mode, language: language, onSuccess: {
                        message = ""
                    }, onDone: {
                        NotificationCenter.default.post(name: .pubgucLoggedIn, object: nil)
                    }, onCancel: {
                        self.mode = nil
                        self.message = ""
                    })
                } else {
                    Button(language == "TR" ? "GİRİŞ YAP" : "LOGIN") {
                        mode = .login
                    }
                    .buttonStyle(GoldButtonStyle())

                    Button(language == "TR" ? "KAYIT OL" : "REGISTER") {
                        mode = .register
                    }
                    .buttonStyle(DarkButtonStyle())

                    Button(language == "TR" ? "SİTEYE GÖZ AT" : "BROWSE WEBSITE") {
                        NotificationCenter.default.post(name: .pubgucBrowse, object: nil)
                    }
                    .buttonStyle(LinkButtonStyle())
                }

                if !message.isEmpty {
                    Text(message).foregroundColor(.red).font(.footnote)
                }

                Spacer()
            }
            .padding(24)
        }
        .onReceive(NotificationCenter.default.publisher(for: .pubgucLoggedIn)) { _ in
            AuthBridge.shared.onLoggedIn?()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pubgucBrowse)) { _ in
            AuthBridge.shared.onBrowse?()
        }
        .onAppear {
            AuthBridge.shared.onLoggedIn = nil
            AuthBridge.shared.onBrowse = nil
        }
    }
}

final class AuthBridge {
    static let shared = AuthBridge()
    var onLoggedIn: (() -> Void)?
    var onBrowse: (() -> Void)?
}

struct AuthForm: View {
    let mode: AuthView.AuthMode
    let language: String
    let onSuccess: () -> Void
    let onDone: () -> Void
    let onCancel: () -> Void

    @State private var username = ""
    @State private var password = ""
    @State private var age = ""
    @State private var pubgId = ""
    @State private var gender = "male"
    @State private var kd = ""
    @State private var tiktok = false
    @State private var youtube = false
    @State private var loading = false
    @State private var error = ""

    var body: some View {
        VStack(spacing: 12) {
            Group {
                TextField(language == "TR" ? "Kullanıcı adı" : "Username", text: $username)
                SecureField(language == "TR" ? "Şifre" : "Password", text: $password)

                if mode == .register {
                    TextField(language == "TR" ? "Yaş" : "Age", text: $age)
                        .keyboardType(.numberPad)
                    TextField("PUBG ID", text: $pubgId)
                        .keyboardType(.numberPad)
                    TextField("KD", text: $kd)
                        .keyboardType(.decimalPad)

                    Picker(language == "TR" ? "Cinsiyet" : "Gender", selection: $gender) {
                        Text(language == "TR" ? "Erkek" : "Male").tag("male")
                        Text(language == "TR" ? "Kadın" : "Female").tag("female")
                    }
                    .pickerStyle(.segmented)

                    Toggle("TikTok", isOn: $tiktok)
                    Toggle("YouTube", isOn: $youtube)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(12)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if !error.isEmpty {
                Text(error).foregroundColor(.red).font(.footnote)
            }

            Button(loading ? "..." : (mode == .login ? (language == "TR" ? "GİRİŞ YAP" : "LOGIN") : (language == "TR" ? "KAYIT OL" : "REGISTER"))) {
                submit()
            }
            .disabled(loading)
            .buttonStyle(GoldButtonStyle())

            Button(language == "TR" ? "GERİ" : "BACK") { onCancel() }
                .buttonStyle(LinkButtonStyle())
        }
    }

    private func submit() {
        error = ""
        loading = true

        Task {
            do {
                if mode == .login {
                    try await API.login(username: username, password: password)
                } else {
                    guard tiktok && youtube else {
                        throw APIError.message(language == "TR" ? "TikTok ve YouTube onayı gerekli." : "TikTok and YouTube confirmation required.")
                    }
                    try await API.register(
                        username: username,
                        password: password,
                        age: Int(age) ?? 0,
                        pubgId: pubgId,
                        gender: gender,
                        kd: kd
                    )
                }
                await MainActor.run {
                    loading = false
                    UserDefaults.standard.set(true, forKey: "pubguc_app_logged_in")
                    onSuccess()
                    onDone()
                }
            } catch {
                await MainActor.run {
                    loading = false
                    self.error = error.localizedDescription
                }
            }
        }
    }
}

struct LangButtonStyle: ButtonStyle {
    let active: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold())
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(active ? Color.yellow.opacity(0.9) : Color.white.opacity(0.08))
            .foregroundColor(active ? .black : .white)
            .clipShape(Capsule())
    }
}

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .green.opacity(0.35), radius: 10)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct DarkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.yellow.opacity(0.7), lineWidth: 1))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct LinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundColor(.green)
            .padding(.vertical, 8)
    }
}

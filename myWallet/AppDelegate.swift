import UIKit
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        print("[INFO] - Uygulama başlatılıyor...")
        FirebaseApp.configure()

        if FirebaseApp.app() != nil {
            print("[FIREBASE] - Firebase bağlantısı başarılı")
        } else {
            print("[ERROR] - Firebase bağlantısı kurulamadı")
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        // Kullanıcı aktif olmayan sahneleri kapattığında tetiklenir.
    }
}

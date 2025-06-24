import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        print("[INFO] - Scene başlatılıyor...")

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        if UserDefaults.standard.bool(forKey: "isLoggedIn") {
            print("[AUTH] - Kullanıcı giriş yapmış. Ana sayfaya yönlendiriliyor.")
            let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController")
            window?.rootViewController = UINavigationController(rootViewController: homeVC)
        } else {
            print("[AUTH] - Giriş yapılmamış. Welcome ekranı gösteriliyor.")
            let welcomeVC = storyboard.instantiateViewController(withIdentifier: "WelcomeViewController")
            window?.rootViewController = UINavigationController(rootViewController: welcomeVC)
        }

        window?.makeKeyAndVisible()
    }

    // Diğer metodlar aynı kalabilir...
}

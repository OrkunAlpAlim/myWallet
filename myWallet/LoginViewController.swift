import UIKit
import FirebaseFirestore

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        print("[INFO] - Login ekranı yüklendi")
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        print("[INFO] - Giriş butonuna tıklandı")

        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Lütfen kullanıcı adı ve şifreyi girin.")
            print("[ALERT] - Kullanıcı adı veya şifre boş")
            return
        }

        print("[FIRESTORE] - Kullanıcı sorgusu başlatılıyor...")
        let db = Firestore.firestore()
        let usersRef = db.collection("users")

        usersRef.whereField("username", isEqualTo: username)
            .whereField("password", isEqualTo: password)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.showAlert(message: "Hata: \(error.localizedDescription)")
                    print("[ERROR] - Firestore hatası: \(error.localizedDescription)")
                } else if let snapshot = snapshot, !snapshot.isEmpty {
                    print("[INFO] - Giriş başarılı")
                    
                    if let document = snapshot.documents.first {
                            let userId = document.documentID
                            UserDefaults.standard.set(true, forKey: "isLoggedIn")
                            UserDefaults.standard.set(userId, forKey: "currentUserId")
                            print("[LOG] - currentUserId kaydedildi: \(userId)")
                        }
                    
                    self.showAlert(message: "Giriş başarılı.") {
                        self.navigateToHome()
                    }
                } else {
                    self.showAlert(message: "Kullanıcı adı veya şifre hatalı.")
                    print("[ALERT] - Giriş başarısız: kullanıcı adı veya şifre yanlış")
                }
            }
    }

    func navigateToHome() {
        print("[NAVIGATION] - Ana sayfaya yönlendiriliyor...")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController")
        navigationController?.pushViewController(homeVC, animated: true)
    }

    func showAlert(message: String, completion: (() -> Void)? = nil) {
        print("[ALERT] - Gösterilen mesaj: \(message)")
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

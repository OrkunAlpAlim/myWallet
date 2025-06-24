import UIKit
import FirebaseFirestore

class RegisterViewController: UIViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var surnameField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        print("[INFO] - Register ekranı yüklendi")
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func registerButtonTapped(_ sender: UIButton) {
        print("[INFO] - Kayıt ol butonuna tıklandı")

        guard let name = nameField.text, !name.isEmpty,
              let surname = surnameField.text, !surname.isEmpty,
              let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordField.text, !confirmPassword.isEmpty else {
            showAlert(message: "Lütfen tüm alanları doldurun.")
            print("[ALERT] - Boş alan tespit edildi")
            return
        }

        guard password == confirmPassword else {
            showAlert(message: "Şifreler eşleşmiyor.")
            print("[ALERT] - Şifreler uyuşmuyor")
            return
        }

        print("[FIRESTORE] - Firestore’a kayıt verisi hazırlanıyor...")
        let db = Firestore.firestore()
        let userRef = db.collection("users").document()
        let userId = userRef.documentID

        let userData: [String: Any] = [
            "userId": userId,
            "username": username,
            "name": name,
            "surname": surname,
            "password": password
        ]

        print("[FIRESTORE] - Kayıt verisi gönderiliyor...")
        userRef.setData(userData) { error in
            if let error = error {
                self.showAlert(message: "Kayıt başarısız: \(error.localizedDescription)")
                print("[ERROR] - Firestore kayıt hatası: \(error.localizedDescription)")
            } else {
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.set(username, forKey: "currentUsername")

                self.showAlert(message: "Kayıt başarılı.") {
                    self.navigateToHome()
                }

                print("[INFO] - Kayıt başarılı, ana sayfaya geçiliyor")
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

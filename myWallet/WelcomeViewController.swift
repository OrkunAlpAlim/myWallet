import UIKit

class WelcomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print("[INFO] - Welcome ekranı yüklendi")
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        print("[NAVIGATION] - Login ekranına geçiliyor")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        navigationController?.pushViewController(loginVC, animated: true)
    }

    @IBAction func registerButtonTapped(_ sender: UIButton) {
        print("[NAVIGATION] - Register ekranına geçiliyor")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let registerVC = storyboard.instantiateViewController(withIdentifier: "RegisterViewController")
        navigationController?.pushViewController(registerVC, animated: true)
    }
}

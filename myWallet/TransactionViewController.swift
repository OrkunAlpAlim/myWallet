import UIKit
import FirebaseFirestore

class TransactionViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var userPicker: UIPickerView!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var transactionTypeSegmented: UISegmentedControl!

    var userList: [(username: String, fullName: String)] = []
    var selectedUsername: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        print("[LOG] - Transaction ekranı yüklendi")

        userPicker.delegate = self
        userPicker.dataSource = self

        fetchUsers()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func fetchUsers() {
        print("[FIRESTORE] - Kullanıcılar çekiliyor...")
        let db = Firestore.firestore()
        guard let currentUsername = UserDefaults.standard.string(forKey: "currentUsername") else {
            print("[ERROR] - currentUsername bulunamadı")
            return
        }

        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("[ERROR] - Kullanıcılar alınamadı: \(error.localizedDescription)")
                return
            }

            self.userList = snapshot?.documents.compactMap {
                let data = $0.data()
                let username = data["username"] as? String ?? ""
                if username == currentUsername { return nil }
                let fullName = "\(data["name"] as? String ?? "") \(data["surname"] as? String ?? "")"
                return (username: username, fullName: fullName)
            } ?? []

            DispatchQueue.main.async {
                self.userPicker.reloadAllComponents()
                if let first = self.userList.first {
                    self.selectedUsername = first.username
                }
            }
        }
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let amountText = amountTextField.text,
              let amount = Double(amountText),
              amount > 0,
              let toUsername = selectedUsername,
              let fromUsername = UserDefaults.standard.string(forKey: "currentUsername") else {
            showAlert("Tüm alanları doğru girin.")
            return
        }

        let type: String
        switch transactionTypeSegmented.selectedSegmentIndex {
        case 0: type = "borrow"
        case 1: type = "lend"
        case 2: type = "collect"
        case 3: type = "pay"
        default:
            showAlert("Lütfen işlem tipini seçin.")
            print("[ALERT] - Geçersiz segment seçimi")
            return
        }

        let db = Firestore.firestore()
        let transactionData: [String: Any] = [
            "fromUsername": fromUsername,
            "toUsername": toUsername,
            "amount": amount,
            "type": type,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("transactions").addDocument(data: transactionData) { error in
            if let error = error {
                print("[ERROR] - Kayıt başarısız: \(error.localizedDescription)")
                self.showAlert("İşlem kaydedilemedi.")
            } else {
                print("[LOG] - İşlem başarıyla kaydedildi.")
                self.showAlert("İşlem kaydedildi.")
            }
        }
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }

    // MARK: - PickerView

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return userList.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return userList[row].fullName
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedUsername = userList[row].username
    }
}

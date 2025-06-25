import UIKit
import FirebaseFirestore

class ChatViewController: UIViewController, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    var messages: [(text: String, from: String)] = []
    var currentUsername: String = ""
    var targetUsername: String = ""
    var targetFullName: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = targetFullName
        tableView.dataSource = self
        currentUsername = UserDefaults.standard.string(forKey: "currentUsername") ?? ""

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)

        listenMessages()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Keyboard Handling

    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardHeight
            }
        }
    }

    @objc func keyboardWillHide(notification: Notification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Firestore Chat

    func listenMessages() {
        let db = Firestore.firestore()
        let chatKey = [currentUsername, targetUsername].sorted().joined(separator: "_")
        
        db.collection("chats")
            .document(chatKey)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("[ERROR] - Mesajlar alınamadı: \(error.localizedDescription)")
                    return
                }

                self.messages = snapshot?.documents.compactMap {
                    let data = $0.data()
                    let text = data["text"] as? String ?? ""
                    let from = data["from"] as? String ?? ""
                    return (text, from)
                } ?? []

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    if self.messages.count > 0 {
                        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                    }
                }
            }
    }

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let text = messageTextField.text, !text.isEmpty else { return }

        let db = Firestore.firestore()
        let chatKey = [currentUsername, targetUsername].sorted().joined(separator: "_")

        let messageData: [String: Any] = [
            "text": text,
            "from": currentUsername,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("chats")
            .document(chatKey)
            .collection("messages")
            .addDocument(data: messageData) { error in
                if let error = error {
                    print("[ERROR] - Mesaj gönderilemedi: \(error.localizedDescription)")
                } else {
                    print("[LOG] - Mesaj gönderildi.")
                    DispatchQueue.main.async {
                        self.messageTextField.text = ""
                    }
                }
            }
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell") ??
                   UITableViewCell(style: .subtitle, reuseIdentifier: "messageCell")
        cell.textLabel?.text = message.text
        cell.detailTextLabel?.text = message.from
        return cell
    }
}

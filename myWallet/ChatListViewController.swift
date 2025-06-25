import UIKit
import FirebaseFirestore

class ChatListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var users: [(username: String, fullName: String)] = []
    var currentUsername: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Mesajlar"
        tableView.delegate = self
        tableView.dataSource = self
        currentUsername = UserDefaults.standard.string(forKey: "currentUsername") ?? ""
        fetchUsers()
    }

    func fetchUsers() {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("[ERROR] - Kullanıcılar alınamadı: \(error.localizedDescription)")
                return
            }

            self.users = snapshot?.documents.compactMap {
                let data = $0.data()
                let username = data["username"] as? String ?? ""
                if username == self.currentUsername { return nil }
                let fullName = "\(data["name"] as? String ?? "") \(data["surname"] as? String ?? "")"
                return (username, fullName)
            } ?? []

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatUserCell") ??
                   UITableViewCell(style: .default, reuseIdentifier: "chatUserCell")
        cell.textLabel?.text = users[indexPath.row].fullName
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = users[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        chatVC.targetUsername = selected.username
        chatVC.targetFullName = selected.fullName
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

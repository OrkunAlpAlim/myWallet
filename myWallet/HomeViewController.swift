import UIKit
import FirebaseFirestore

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalLabel: UILabel!

    var users: [UserModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        print("[LOG] - Home ekranı açıldı")
        setupNavigationBar()
        setupTableView()
        startListeningForTransactions()
    }

    func setupNavigationBar() {
        self.navigationItem.hidesBackButton = true
        self.title = "Ana Sayfa"

        let plusButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(plusTapped))
        let chatButton = UIBarButtonItem(image: UIImage(systemName: "message"), style: .plain, target: self, action: #selector(chatTapped))
        let logoutButton = UIBarButtonItem(title: "Çıkış Yap", style: .plain, target: self, action: #selector(logoutTapped))

        self.navigationItem.rightBarButtonItems = [plusButton, chatButton]
        self.navigationItem.leftBarButtonItem = logoutButton
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    func fetchUsers() {
        print("[LOG] - Kullanıcılar Firestore'dan çekiliyor...")
        let db = Firestore.firestore()

        guard let currentUsername = UserDefaults.standard.string(forKey: "currentUsername") else {
            print("[ERROR] - currentUsername bulunamadı.")
            return
        }

        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("[ERROR] - Kullanıcılar alınamadı: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            self.users.removeAll()
            var totalBalance: Double = 0.0
            let group = DispatchGroup()

            for doc in documents {
                let data = doc.data()
                let otherUsername = data["username"] as? String ?? ""
                if otherUsername == currentUsername { continue }

                let name = data["name"] as? String ?? ""
                let surname = data["surname"] as? String ?? ""
                var balance: Double = 0.0
                group.enter()

                db.collection("transactions").getDocuments { snap, _ in
                    for doc in snap?.documents ?? [] {
                        let data = doc.data()
                        let from = data["fromUsername"] as? String ?? ""
                        let to = data["toUsername"] as? String ?? ""
                        let type = (data["type"] as? String ?? "").lowercased()
                        let amount = data["amount"] as? Double ?? 0.0

                        let involved = (from == currentUsername && to == otherUsername) ||
                                       (from == otherUsername && to == currentUsername)
                        if !involved { continue }

                        switch type {
                            case "lend":
                                if from == currentUsername { balance += amount }
                                else if to == currentUsername { balance -= amount }

                            case "borrow":
                                if from == currentUsername { balance -= amount }
                                else if to == currentUsername { balance += amount }

                            case "pay":
                                if from == currentUsername { balance += amount }
                                else if to == currentUsername { balance -= amount }

                            case "collect":
                                if from == currentUsername { balance -= amount }
                                else if to == currentUsername { balance += amount }

                            default: break
                        }
                    }

                    self.users.append(UserModel(name: name, surname: surname, balance: balance, username: otherUsername))


                    totalBalance += balance
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.tableView.reloadData()
                self.totalLabel.text = String(format: "Toplam Tutar: %.2f ₺", totalBalance)
                print("[LOG] - Kullanıcılar ve bakiyeler hesaplandı. Toplam: \(totalBalance)")
            }
        }
    }

    func startListeningForTransactions() {
        guard let _ = UserDefaults.standard.string(forKey: "currentUsername") else {
            print("[ERROR] - currentUsername bulunamadı.")
            return
        }

        Firestore.firestore().collection("transactions").addSnapshotListener { _, _ in
            print("[REALTIME] - İşlem değişikliği algılandı. Kullanıcılar güncelleniyor.")
            self.fetchUsers()
        }
    }

    @objc func logoutTapped() {
        let alert = UIAlertController(title: "Çıkış Yap", message: "Emin misiniz?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Evet", style: .destructive, handler: { _ in
            print("[LOGOUT] - Oturum kapatılıyor...")
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "currentUsername")

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let welcomeVC = storyboard.instantiateViewController(withIdentifier: "WelcomeViewController")

            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first {
                window.rootViewController = UINavigationController(rootViewController: welcomeVC)
                window.makeKeyAndVisible()
            }
        }))
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alert, animated: true)
    }

    @objc func plusTapped() {
        print("[NAVIGATION] - İşlem ekranına geçiliyor")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let transactionVC = storyboard.instantiateViewController(withIdentifier: "TransactionViewController")
        navigationController?.pushViewController(transactionVC, animated: true)
    }

    @objc func chatTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let chatListVC = storyboard.instantiateViewController(withIdentifier: "ChatListViewController")
        navigationController?.pushViewController(chatListVC, animated: true)
    }


    // MARK: - TableView Delegate & DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = users[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell") ??
                   UITableViewCell(style: .value1, reuseIdentifier: "userCell")

        cell.textLabel?.text = "\(user.name) \(user.surname)"
        cell.detailTextLabel?.text = String(format: "%.2f ₺", user.balance)
        cell.detailTextLabel?.textColor = user.balance >= 0 ? .systemGreen : .systemRed
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = users[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let detailVC = storyboard.instantiateViewController(withIdentifier: "UserDetailViewController") as! UserDetailViewController
        detailVC.selectedUsername = selectedUser.username
        detailVC.selectedFullName = "\(selectedUser.name) \(selectedUser.surname)"
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

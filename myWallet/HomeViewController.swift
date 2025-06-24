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
        fetchUsers()
    }

    func setupNavigationBar() {
        self.navigationItem.hidesBackButton = true
        self.title = "myWallet"

        let plusButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(plusTapped)
        )

        let chatButton = UIBarButtonItem(
            image: UIImage(systemName: "message"),
            style: .plain,
            target: self,
            action: #selector(chatTapped)
        )

        let logoutButton = UIBarButtonItem(
            title: "Çıkış Yap",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )

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

        guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") else {
            print("[ERROR] - currentUserId bulunamadı.")
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
                let userId = doc.documentID
                if userId == currentUserId { continue }

                let name = data["name"] as? String ?? ""
                let surname = data["surname"] as? String ?? ""
                var balance: Double = 0.0
                group.enter()

                // İşlemleri paralel hesapla
                let transactionsRef = db.collection("transactions")

                let query1 = transactionsRef
                    .whereField("fromUserId", isEqualTo: currentUserId)
                    .whereField("toUserId", isEqualTo: userId)

                let query2 = transactionsRef
                    .whereField("fromUserId", isEqualTo: userId)
                    .whereField("toUserId", isEqualTo: currentUserId)

                // 1. current → other
                query1.getDocuments { fromSnapshot, _ in
                    for doc in fromSnapshot?.documents ?? [] {
                        let amount = doc["amount"] as? Double ?? 0.0
                        let type = doc["type"] as? String ?? ""
                        if type == "lend" { balance += amount }
                        else if type == "pay" { balance -= amount }
                    }

                    // 2. other → current
                    query2.getDocuments { toSnapshot, _ in
                        for doc in toSnapshot?.documents ?? [] {
                            let amount = doc["amount"] as? Double ?? 0.0
                            let type = doc["type"] as? String ?? ""
                            if type == "borrow" { balance -= amount }
                            else if type == "collect" { balance += amount }
                        }

                        self.users.append(UserModel(name: name, surname: surname, balance: balance))
                        totalBalance += balance
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                self.tableView.reloadData()
                self.totalLabel.text = String(format: "Toplam Tutar: %.2f ₺", totalBalance)
                print("[LOG] - Kullanıcılar ve bakiyeler hesaplandı. Toplam: \(totalBalance)")
            }
        }
    }


    @objc func logoutTapped() {
        let alert = UIAlertController(
            title: "Çıkış Yap",
            message: "Emin misiniz?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Evet", style: .destructive, handler: { _ in
            print("[LOGOUT] - Oturum kapatılıyor...")
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "currentUserId")

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
        // TODO: TransactionViewController'a geçiş yapılacak
    }

    @objc func chatTapped() {
        print("[NAVIGATION] - Mesajlaşma ekranına geçiliyor")
        // TODO: ChatViewController'a geçiş yapılacak
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
}

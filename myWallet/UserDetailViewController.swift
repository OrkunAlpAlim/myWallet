import UIKit
import FirebaseFirestore

class UserDetailViewController: UIViewController, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalLabel: UILabel!

    var transactions: [TransactionModel] = []

    var selectedUsername: String = ""
    var selectedFullName: String = ""
    var currentUsername: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = selectedFullName
        tableView.dataSource = self
        currentUsername = UserDefaults.standard.string(forKey: "currentUsername") ?? ""
        setupDeleteButton()
        fetchTransactions()
    }

    func setupDeleteButton() {
        let deleteButton = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(deleteAllTransactions)
        )
        self.navigationItem.rightBarButtonItem = deleteButton
    }

    func fetchTransactions() {
        let db = Firestore.firestore()

        db.collection("transactions")
            .order(by: "timestamp", descending: true)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("[ERROR] - İşlemler alınamadı: \(error.localizedDescription)")
                    return
                }

                self.transactions = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    let from = data["fromUsername"] as? String ?? ""
                    let to = data["toUsername"] as? String ?? ""

                    // Sadece current ve selected kullanıcıları içeren işlemler
                    let isInvolved = (from == self.currentUsername && to == self.selectedUsername) ||
                                     (from == self.selectedUsername && to == self.currentUsername)
                    if !isInvolved { return nil }

                    return TransactionModel(
                        id: doc.documentID,
                        from: from,
                        to: to,
                        type: data["type"] as? String ?? "",
                        amount: data["amount"] as? Double ?? 0.0,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue()
                    )
                } ?? []

                let total = self.calculateTotal()
                DispatchQueue.main.async {
                    self.totalLabel.text = String(format: "Toplam Tutar: %.2f ₺", total)
                    self.tableView.reloadData()
                }
            }
    }

    func calculateTotal() -> Double {
        var total: Double = 0.0
        for tx in transactions {
            switch tx.type.lowercased() {
                case "lend":
                    total += tx.from == currentUsername ? tx.amount : -tx.amount
                case "borrow":
                    total += tx.from == currentUsername ? -tx.amount : tx.amount
                case "pay":
                    total += tx.from == currentUsername ? tx.amount : -tx.amount
                case "collect":
                    total += tx.from == currentUsername ? -tx.amount : tx.amount
                default: break
            }
        }
        return total
    }

    @objc func deleteAllTransactions() {
        let alert = UIAlertController(
            title: "Tüm İşlemleri Sil",
            message: "\(selectedFullName) ile tüm işlemleri silmek istiyor musunuz?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Evet", style: .destructive) { _ in
            self.performDeletion()
        })
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alert, animated: true)
    }

    func performDeletion() {
        let db = Firestore.firestore()

        db.collection("transactions")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("[ERROR] - Silme başarısız: \(error.localizedDescription)")
                    return
                }

                let batch = db.batch()
                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    let from = data["fromUsername"] as? String ?? ""
                    let to = data["toUsername"] as? String ?? ""

                    let isInvolved = (from == self.currentUsername && to == self.selectedUsername) ||
                                     (from == self.selectedUsername && to == self.currentUsername)

                    if isInvolved {
                        batch.deleteDocument(doc.reference)
                    }
                }

                batch.commit { error in
                    if let error = error {
                        print("[ERROR] - Toplu silme hatası: \(error.localizedDescription)")
                    } else {
                        print("[LOG] - İşlemler başarıyla silindi.")
                        self.transactions.removeAll()
                        self.totalLabel.text = "Toplam Tutar: 0.00 ₺"
                        self.tableView.reloadData()
                    }
                }
            }
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tx = transactions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "txCell") ??
                   UITableViewCell(style: .subtitle, reuseIdentifier: "txCell")

        let direction = tx.from == currentUsername ? "→" : "←"
        let target = tx.from == currentUsername ? tx.to : tx.from
        cell.textLabel?.text = "\(tx.type.uppercased()) \(direction) \(target)"
        cell.detailTextLabel?.text = String(format: "%.2f ₺ | %@", tx.amount, tx.timestamp?.description(with: .current) ?? "")
        return cell
    }
}

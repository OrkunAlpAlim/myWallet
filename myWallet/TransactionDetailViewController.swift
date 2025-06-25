import UIKit
import FirebaseFirestore

class TransactionDetailViewController: UIViewController {

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    var transaction: TransactionModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "İşlem Detayı"
        showTransactionDetails()
    }

    func showTransactionDetails() {
        typeLabel.text = "Tür: \(transaction.type.capitalized)"
        fromLabel.text = "Gönderen: \(transaction.from)"
        toLabel.text = "Alıcı: \(transaction.to)"
        
        let formattedDate = transaction.timestamp?.formatted(date: .numeric, time: .shortened) ?? "-"
        amountLabel.text = String(format: "Tutar: %.2f ₺ | %@", transaction.amount, formattedDate)
    }

    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "İşlemi Sil", message: "Bu işlemi silmek istiyor musunuz?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Evet", style: .destructive) { _ in
            self.performDeletion()
        })
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alert, animated: true)
    }

    func performDeletion() {
        Firestore.firestore().collection("transactions").document(transaction.id).delete { error in
            if let error = error {
                print("[ERROR] - Silme hatası: \(error.localizedDescription)")
            } else {
                print("[LOG] - İşlem silindi.")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

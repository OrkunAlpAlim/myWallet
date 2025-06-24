import Foundation
import FirebaseFirestore

struct TransactionModel {
    var id: String
    var from: String
    var to: String
    var type: String
    var amount: Double
    var timestamp: Date?
}

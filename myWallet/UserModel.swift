struct UserModel {
    var name: String
    var surname: String
    var username: String
    var balance: Double

    init(name: String, surname: String, balance: Double, username: String) {
        self.name = name
        self.surname = surname
        self.balance = balance
        self.username = username
    }
}

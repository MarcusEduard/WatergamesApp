import FirebaseFirestore

extension Participant {
    init?(document: DocumentSnapshot) {
        let data = document.data()
        guard
            let name = data?["name"] as? String,
            let phone = data?["phone"] as? String,
            let couponCode = data?["couponCode"] as? String,
            let attended = data?["attended"] as? Bool,
            let paid = data?["paid"] as? Bool
        else { return nil }

        self.id = document.documentID
        self.name = name
        self.phone = phone
        self.couponCode = couponCode
        self.attended = attended
        self.paid = paid
    }

    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "phone": phone,
            "couponCode": couponCode,
            "attended": attended,
            "paid": paid
        ]
    }
}

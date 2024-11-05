import Firebase
import FirebaseFirestore
import FirebaseAuth

class FirebaseHelper: ObservableObject {
    private let db = Firestore.firestore()

    func uploadCSVData(courseType: String, city: String, holdNumber: String, csvData: String, completion: @escaping (Bool) -> Void) {
        let documentId = "\(courseType)_\(city)_\(holdNumber)"
        db.collection("courses").document(documentId).setData(["csvData": csvData]) { error in
            completion(error == nil)
        }
    }

    func fetchCSVData(courseType: String, city: String, holdNumber: String, completion: @escaping (String?) -> Void) {
        let documentId = "\(courseType)_\(city)_\(holdNumber)"
        db.collection("courses").document(documentId).getDocument { snapshot, error in
            if let data = snapshot?.data(), let csvData = data["csvData"] as? String {
                completion(csvData)
            } else {
                completion(nil)
            }
        }
    }

    func fetchHoldsForCourse(courseType: String, city: String, completion: @escaping ([String]) -> Void) {
        db.collection("courses").whereField("courseType", isEqualTo: courseType).whereField("city", isEqualTo: city).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            let holds = documents.compactMap { $0.documentID }
            completion(holds)
        }
    }

    func subscribeToCourseUpdates(completion: @escaping () -> Void) {
        db.collection("courses").addSnapshotListener { _, _ in
            completion()
        }
    }
}

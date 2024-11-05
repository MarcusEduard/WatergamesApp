import SwiftUI
import MessageUI
import FirebaseFirestore

struct Participant: Identifiable {
    var id: Int
    var name: String
    var phone: String
    var couponCode: String
    var attended: Bool = false
    var paid: Bool = false
}

struct AttendanceView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCourse: String = ""
    @State private var selectedCity: String = ""
    @State private var selectedHold: String = ""
    @State private var participants: [Participant] = []
    @State private var showMailComposer = false
    @State private var availableHolds: [String] = []

    let courseTypes = ["Speedbåd", "Vandscooter", "Duelighed Teori", "Duelighed Praktik", "Sejlads i sejlbåd", "Yachtskipper 1", "Yachtskipper 3", "VHF|SRC", "Motorpasser"]
    let cities = ["Aalborg", "Aarhus", "Struer", "Middelfart", "Rungsted", "Brøndby", "Out of office"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Trin 1: Valg af kursustype
                if selectedCourse.isEmpty {
                    Text("Vælg Kursustype")
                        .font(.headline)
                        .padding()

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                        ForEach(courseTypes, id: \.self) { course in
                            Button(action: {
                                selectedCourse = course
                            }) {
                                Text(course)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
                
                // Trin 2: Valg af by
                else if selectedCity.isEmpty {
                    Text("Vælg By for \(selectedCourse)")
                        .font(.headline)
                        .padding()

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                        ForEach(cities, id: \.self) { city in
                            Button(action: {
                                selectedCity = city
                                loadAvailableHolds()
                            }) {
                                Text(city)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
                
                // Trin 3: Visning af hold eller besked
                else if !selectedHold.isEmpty {
                    if participants.isEmpty {
                        Text("Ingen deltagere fundet for \(selectedHold).")
                            .padding()
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(participants.indices, id: \.self) { index in
                                ParticipantRow(participant: $participants[index])
                            }
                        }
                        .padding()
                        
                        Button(action: {
                            showMailComposer = true
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Send Rapport")
                            }
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .sheet(isPresented: $showMailComposer) {
                            MailView(
                                isShowing: $showMailComposer,
                                result: .constant(nil),
                                report: generateEmailContent(),
                                selectedHold: selectedHold,
                                onMailSent: clearParticipantsData
                            )
                        }
                    }
                } else {
                    Text("Vælg Hold i \(selectedCity) for \(selectedCourse)")
                        .font(.headline)
                        .padding()

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                        ForEach(availableHolds, id: \.self) { hold in
                            Button(action: {
                                selectedHold = hold
                                loadParticipants()
                            }) {
                                Text(hold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.orange.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
        .onAppear(perform: loadAvailableHolds)
    }

    private func loadParticipants() {
        let db = Firestore.firestore()
        let documentId = "\(selectedCourse)_\(selectedCity)_\(selectedHold)"
        
        print("Loading participants for document ID: \(documentId)") // Debug print

        db.collection("courses").document(documentId).getDocument { (document, error) in
            if let document = document, document.exists {
                if let csvData = document.data()?["csvData"] as? String {
                    print("CSV Data found: \(csvData)") // Debug print
                    parseCSVData(csvData)
                }
            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    private func parseCSVData(_ data: String) {
        participants = []
        let rows = data.components(separatedBy: "\n")
        guard let headerRow = rows.first else { return }
        let headers = headerRow.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }

        let nameIndex = headers.firstIndex(of: "customer name".lowercased()) ?? -1
        let phoneIndex = headers.firstIndex(of: "telefonnummer".lowercased()) ?? -1
        let couponCodeIndex = headers.firstIndex(of: "coupon code".lowercased()) ?? -1

        guard nameIndex != -1, phoneIndex != -1, couponCodeIndex != -1 else {
            print("Nødvendige kolonner ikke fundet")
            return
        }

        for (index, row) in rows.dropFirst().enumerated() {
            let columns = row.components(separatedBy: ",")
            if columns.count > max(nameIndex, phoneIndex, couponCodeIndex) {
                let participant = Participant(
                    id: index,
                    name: columns[nameIndex].trimmingCharacters(in: .whitespaces),
                    phone: columns[phoneIndex].trimmingCharacters(in: .whitespaces),
                    couponCode: columns[couponCodeIndex].trimmingCharacters(in: .whitespaces)
                )
                participants.append(participant)
                print("Participant added: \(participant)") // Debug print
            }
        }

        print("Total participants loaded: \(participants.count)") // Debug print
    }

    private func loadAvailableHolds() {
        guard !selectedCourse.isEmpty && !selectedCity.isEmpty else { return }
        
        let db = Firestore.firestore()
        db.collection("courses").whereField("kursusType", isEqualTo: selectedCourse)
            .whereField("city", isEqualTo: selectedCity)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Fejl ved hentning af holds: \(error)")
                    return
                }
                
                self.availableHolds = snapshot?.documents.compactMap { $0.data()["holdNumber"] as? String } ?? []
                self.availableHolds.sort()
            }
    }

    private func generateEmailContent() -> String {
        var emailBody = "Deltagerliste for \(selectedHold)\n\n"

        for participant in participants {
            let attendedText = participant.attended ? "Ja" : "Nej"
            let paidText = participant.paid ? "Ja" : "Nej"
            emailBody += "- Deltager: \(participant.name) (\(participant.phone)) \n\t Mødt: \(attendedText) \n\t Betalt: \(paidText)\n"
        }

        emailBody += "\n Opsummering:\n"
        return emailBody
    }

    private func clearParticipantsData() {
        let db = Firestore.firestore()
        let documentId = "\(selectedCourse)_\(selectedCity)_\(selectedHold)"
        
        db.collection("courses").document(documentId).delete { error in
            if let error = error {
                print("Fejl ved sletning af hold i Firebase: \(error)")
            } else {
                print("Hold slettet fra Firebase.")
            }
        }
        
        participants.removeAll()
    }
}

struct ParticipantRow: View {
    @Binding var participant: Participant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(participant.name)
                .font(.headline)
            Text(participant.phone)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("Note: \(participant.couponCode)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Toggle("Mødt", isOn: $participant.attended)
                Toggle("Betalt", isOn: $participant.paid)
            }
            .toggleStyle(SwitchToggleStyle())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}


struct AttendanceView_Previews: PreviewProvider {
    static var previews: some View {
        AttendanceView()
    }
}

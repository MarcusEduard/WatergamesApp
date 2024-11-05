import SwiftUI
import MessageUI

struct Participant: Identifiable {
    var id: Int
    var name: String
    var phone: String
    var couponCode: String
    var attended: Bool = false // Standardværdi
    var paid: Bool = false     // Standardværdi
}

struct AttendanceView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedHold: String = ""
    @State private var participants: [Participant] = []
    @State private var showMailComposer = false
    @State private var reportSummary: String = ""

    @AppStorage("hold1Data") var hold1Data: String = ""
    @AppStorage("hold2Data") var hold2Data: String = ""

    let holdNames = ["Hold 1", "Hold 2"]

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                            Spacer()
                            HStack(spacing: 16) {
                                ForEach(holdNames, id: \.self) { hold in
                                    Button(hold) {
                                        selectedHold = hold
                                        loadParticipants()
                                    }
                                    .padding()
                                    .background(selectedHold == hold ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                        }
                        .padding(.top)

            if selectedHold.isEmpty {
                Text("Intet hold valgt, vælg et hold")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if participants.isEmpty {
                Text("Ingen deltagere fundet for dette hold.")
                    .padding()
            } else {
                List {
                    ForEach(participants.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(participants[index].name)
                                Spacer()
                                Text(participants[index].phone)
                            }

                            Text("Note: \(participants[index].couponCode)")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            HStack {
                                Toggle("Mødt", isOn: $participants[index].attended)
                                Toggle("Betalt", isOn: $participants[index].paid)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Button("Send Rapport") {
                showMailComposer = true
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
                    onMailSent: clearParticipantsData // Opdatering: Kalder clearParticipantsData når mailen sendes
                )
            }
        }
    }

    private func generateEmailContent() -> String {
        var emailBody = "Deltagerliste for \(selectedHold)\n\n"

        for participant in participants {
            let attendedText = participant.attended ? "Ja" : "Nej"
            let paidText = participant.paid ? "Ja" : "Nej"
            emailBody += "Deltager: \(participant.name) (\(participant.phone)) - Mødt: \(attendedText) - Betaling: \(paidText)\n"
        }

        emailBody += "\nOpsummering:\n"

        return emailBody
    }

    private func loadParticipants() {
        participants = []
        let data = selectedHold == "Hold 1" ? hold1Data : hold2Data
        let rows = data.components(separatedBy: "\n")
        for (index, row) in rows.enumerated() {
            let columns = row.components(separatedBy: ",")
            if columns.count >= 3 {
                let participant = Participant(
                    id: index,
                    name: columns[0],
                    phone: columns[1],
                    couponCode: columns[2]
                )
                participants.append(participant)
            }
        }
    }

    private func clearParticipantsData() {
        if selectedHold == "Hold 1" {
            hold1Data = "" // Rydder Hold 1 data
        } else if selectedHold == "Hold 2" {
            hold2Data = "" // Rydder Hold 2 data
        }
        participants.removeAll() // Fjerner alle deltagere fra listen
    }
}

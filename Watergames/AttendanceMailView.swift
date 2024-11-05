import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?
    var report: String
    var selectedHold: String
    var onMailSent: () -> Void // Callback for at udføre slettefunktion
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(["kursus@watergames.dk"]) // Sæt modtager
        vc.setSubject("Deltagerliste for \(selectedHold)") // Sæt emnet
        vc.setMessageBody(report, isHTML: false) // Sæt brødtekst
        vc.mailComposeDelegate = context.coordinator // Tildel delegate
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // Ingen opdatering nødvendig
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isShowing: $isShowing, result: $result, onMailSent: onMailSent)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isShowing: Bool
        @Binding var result: Result<MFMailComposeResult, Error>?
        var onMailSent: () -> Void // Callback reference
        
        init(isShowing: Binding<Bool>, result: Binding<Result<MFMailComposeResult, Error>?>, onMailSent: @escaping () -> Void) {
            _isShowing = isShowing
            _result = result
            self.onMailSent = onMailSent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                self.result = .failure(error)
            } else {
                self.result = .success(result)
                
                // Kald onMailSent callback, når e-mail er sendt
                if result == .sent {
                    onMailSent()
                }
            }
            isShowing = false
        }
    }
}

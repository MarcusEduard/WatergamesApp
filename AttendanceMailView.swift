import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    var report: String
    var selectedHold: String
    var onMailSent: () -> Void

    private let recipientEmail = "marcuseduard@hotmail.dk"

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipientEmail])
        vc.setSubject("Deltagerliste for \(selectedHold)")
        vc.setMessageBody(report, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<MailView>) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(isShowing: $isShowing, result: $result, onMailSent: onMailSent)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isShowing: Bool
        @Binding var result: Result<MFMailComposeResult, Error>?
        var onMailSent: () -> Void

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
                
                // Kontroller, om mailen blev sendt (success)
                if result == .sent {
                    // Kald clearParticipantsData() for at rydde data kun hvis mailen blev sendt
                    onMailSent()
                }
            }
            isShowing = false
        }
    }
}

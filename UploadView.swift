import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @State private var csvFileContent: String = ""
    @State private var selectedHold: String = "Hold 1" // Standard værdi
    @State private var showDocumentPicker = false
    @State private var isUploadSuccessful = false
    @State private var isFileSelected = false

    // Gemmer deltagerdata fra CSV
    @AppStorage("hold1Data") var hold1Data: String = ""
    @AppStorage("hold2Data") var hold2Data: String = ""

    // Hold navne
    let holdNames = ["Hold 1", "Hold 2"]

    var body: some View {
        VStack {
            // Dropdown til at vælge hold
            Picker("Vælg Hold", selection: $selectedHold) {
                ForEach(holdNames, id: \.self) { hold in
                    Text(hold).tag(hold)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            Button("Vælg CSV-fil") {
                showDocumentPicker = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker { result in
                    switch result {
                    case .success(let content):
                        csvFileContent = content
                        isFileSelected = true
                    case .failure(let error):
                        print("Fejl ved læsning af fil: \(error)")
                    }
                }
            }

            // Viser upload-knappen kun hvis filen er valgt
            if isFileSelected {
                Button("Upload CSV") {
                    uploadCSV(for: selectedHold, content: csvFileContent)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            // Viser en meddelelse, når upload er succesfuld
            if isUploadSuccessful {
                Text("Tildelt Hold: \(selectedHold)")
                    .font(.headline)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Text("CSV Indhold:")
                .font(.headline)
                .padding()
            ScrollView {
                Text(csvFileContent)
                    .padding()
            }

            Spacer()
        }
        .navigationTitle("Upload CSV")
    }

    // Funktion til at gemme CSV-indholdet i AppStorage baseret på valgt hold
    private func uploadCSV(for hold: String, content: String) {
        if hold == "Hold 1" {
            hold1Data = content // Gemmer indholdet til Hold 1
            print("Hold 1 CSV data gemt: \(hold1Data)")
        } else if hold == "Hold 2" {
            hold2Data = content // Gemmer indholdet til Hold 2
            print("Hold 2 CSV data gemt: \(hold2Data)")
        }
        isUploadSuccessful = true
        isFileSelected = false
    }
}

// Dokumentvælger
struct DocumentPicker: UIViewControllerRepresentable {
    var completionHandler: (Result<String, Error>) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.commaSeparatedText])
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self, completionHandler: completionHandler)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        var completionHandler: (Result<String, Error>) -> Void
        
        init(_ parent: DocumentPicker, completionHandler: @escaping (Result<String, Error>) -> Void) {
            self.parent = parent
            self.completionHandler = completionHandler
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            // Start accessing the file's secured resource
            let isAccessing = url.startAccessingSecurityScopedResource()

            defer {
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let content = try String(contentsOf: url)
                completionHandler(.success(content))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}

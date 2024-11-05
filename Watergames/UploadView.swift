import SwiftUI
import UniformTypeIdentifiers
import FirebaseFirestore

struct UploadView: View {
    @State private var csvFileContent: String = ""
    @State private var selectedKursusType: String?
    @State private var selectedCity: String?
    @State private var holdNumber: String = ""
    @State private var showDocumentPicker = false
    @State private var isUploadSuccessful = false
    @State private var isFileSelected = false
    @State private var showKursusTypes = false
    @State private var showCities = false
    
    let kursusTypes = ["Speedbåd", "Vandscooter", "Duelighed Teori", "Duelighed Praktik", "Sejlads i sejlbåd", "Yachtskipper 1", "Yachtskipper 3", "VHF|SRC", "Motorpasser"]
    let cities = ["Aalborg", "Aarhus", "Struer", "Middelfart", "Rungsted", "Brøndby", "Out of office"]

    var body: some View {
        VStack(spacing: 16) {
            Button(action: { showKursusTypes.toggle() }) {
                Text(selectedKursusType ?? "Vælg Kursus")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.black)
                    .font(.headline)
            }
            .sheet(isPresented: $showKursusTypes) {
                List(kursusTypes, id: \.self) { kursus in
                    Button(kursus) {
                        selectedKursusType = kursus
                        showKursusTypes = false
                    }
                }
            }

            Button(action: { showCities.toggle() }) {
                Text(selectedCity ?? "Vælg By")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.black)
                    .font(.headline)
            }
            .sheet(isPresented: $showCities) {
                List(cities, id: \.self) { city in
                    Button(city) {
                        selectedCity = city
                        showCities = false
                    }
                }
            }

            TextField("Indtast Holdnummer", text: $holdNumber)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .font(.headline)
                .padding(.horizontal)

            Button(action: { showDocumentPicker = true }) {
                HStack {
                    Image(systemName: "doc.fill")
                    Text("Vælg CSV-fil")
                }
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(10)
            .foregroundColor(.black)
            .font(.headline)
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(csvFileContent: $csvFileContent, isFileSelected: $isFileSelected)
            }

            if isFileSelected {
                Text("Fil Indhold:")
                    .font(.headline)
                ScrollView {
                    Text(csvFileContent)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
                .frame(height: 200)
            }

            Button(action: uploadData) {
                Text("Upload Data")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.black)
                    .font(.headline)
            }
            .disabled(!isFileSelected || selectedKursusType == nil || selectedCity == nil || holdNumber.isEmpty)

            if isUploadSuccessful {
                Text("Data uploadet med succes!")
                    .foregroundColor(.green)
                    .font(.headline)
            }
        }
        .padding()
    }

    private func uploadData() {
        guard let selectedKursusType = selectedKursusType, let selectedCity = selectedCity else { return }

        let sanitizedKursusType = selectedKursusType.replacingOccurrences(of: "/", with: "_")
        let documentId = "\(sanitizedKursusType)_\(selectedCity)_\(holdNumber)"
        
        print("Starting data upload for document ID: \(documentId)")

        let db = Firestore.firestore()
        let kursusData = [
            "kursusType": selectedKursusType,
            "city": selectedCity,
            "holdNumber": holdNumber,
            "csvData": csvFileContent
        ]
        
        db.collection("courses").document(documentId).setData(kursusData) { error in
            if let error = error {
                print("Error uploading data: \(error)")
            } else {
                isUploadSuccessful = true
                clearForm()
                print("Data uploaded successfully for document ID: \(documentId)")
            }
        }
    }

    private func clearForm() {
        selectedKursusType = nil
        selectedCity = nil
        holdNumber = ""
        csvFileContent = ""
        isFileSelected = false
    }
}


// DocumentPicker
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var csvFileContent: String
    @Binding var isFileSelected: Bool

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.commaSeparatedText])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedFileURL = urls.first else {
                print("Ingen fil blev valgt.")
                return
            }

            // Start accessing security scoped resource
            if selectedFileURL.startAccessingSecurityScopedResource() {
                defer { selectedFileURL.stopAccessingSecurityScopedResource() }
                
                let tempDirectory = FileManager.default.temporaryDirectory
                let tempFileURL = tempDirectory.appendingPathComponent(selectedFileURL.lastPathComponent)

                do {
                    if FileManager.default.fileExists(atPath: tempFileURL.path) {
                        try FileManager.default.removeItem(at: tempFileURL)
                    }
                    
                    try FileManager.default.copyItem(at: selectedFileURL, to: tempFileURL)
                    let content = try String(contentsOf: tempFileURL, encoding: .utf8)
                    parent.csvFileContent = content
                    parent.isFileSelected = true
                    print("Fil valgt og indlæst: \(content)")

                } catch {
                    print("Kunne ikke kopiere eller læse filens indhold: \(error)")
                }
            } else {
                print("Kunne ikke få adgang til filen på grund af sikkerhedsbegrænsninger.")
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isFileSelected = false
        }
    }
}

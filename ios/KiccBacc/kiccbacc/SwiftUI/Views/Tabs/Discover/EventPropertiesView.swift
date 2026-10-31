//
//  EventPropertiesView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 21/09/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFunctions

struct EventPropertiesView: View {
    @Environment(\.dismiss) private var dismiss
    
    let event: Event
    let onEventUpdated: ((Event) -> Void)?
    @State private var showStories: Bool
    @State private var showTicketsSold: Bool
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showImportListSheet = false
    
    init(event: Event, onEventUpdated: ((Event) -> Void)? = nil) {
        self.event = event
        self.onEventUpdated = onEventUpdated
        self._showStories = State(initialValue: event.showStories)
        self._showTicketsSold = State(initialValue: event.showTicketsSold)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event Properties")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Configure how your event appears to attendees")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Properties Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Display Settings")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            // Show Stories Toggle
                            PropertyToggleRow(
                                title: "Show Stories",
                                description: "Allow attendees to view and upload stories for this event",
                                icon: "camera.fill",
                                isEnabled: $showStories
                            )
                            
                            // Show Tickets Sold Toggle
                            PropertyToggleRow(
                                title: "Show Tickets Sold",
                                description: "Display the number of tickets sold to attendees",
                                icon: "ticket.fill",
                                isEnabled: $showTicketsSold
                            )
                            
                            // Import List Button
                            Button(action: {
                                showImportListSheet = true
                            }) {
                                HStack(alignment: .top, spacing: 15) {
                                    // Icon
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.blue)
                                        .frame(width: 24, height: 24)
                                    
                                    // Content
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Import List")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Text("Import email list from Excel or Spreadsheet to send invitations")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    
                                    Spacer()
                                    
                                    // Arrow
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Save Button
                    Button(action: saveProperties) {
                        HStack {
                            if isUpdating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            
                            Text(isUpdating ? "Saving..." : "Save Changes")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(hasChanges ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isUpdating || !hasChanges)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Properties")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Properties Updated", isPresented: $showAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showImportListSheet) {
            ImportListSheet(event: event)
        }
    }
    
    private var hasChanges: Bool {
        showStories != event.showStories || showTicketsSold != event.showTicketsSold
    }
    
    private func saveProperties() {
        guard hasChanges else { return }
        
        isUpdating = true
        
        var updateValues: [String: Any] = [:]
        updateValues["showStories"] = showStories
        updateValues["showTicketsSold"] = showTicketsSold
        
        EventManager.shared.updateEventWith(eventID: event.eventID, with: updateValues) { isUpdated in
            DispatchQueue.main.async {
                isUpdating = false
                
                if isUpdated {
                    // Create updated event with new properties
                    var updatedEvent = event
                    updatedEvent.showStories = showStories
                    updatedEvent.showTicketsSold = showTicketsSold
                    
                    // Notify parent view of the update
                    onEventUpdated?(updatedEvent)
                    
                    alertMessage = "Event properties have been updated successfully."
                    showAlert = true
                } else {
                    alertMessage = "Failed to update event properties. Please try again."
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Property Toggle Row
struct PropertyToggleRow: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isEnabled ? .blue : .gray)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Import List Sheet
struct ImportListSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let event: Event
    
    @State private var selectedFile: URL?
    @State private var isProcessing = false
    @State private var showDocumentPicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var importedEmails: [String] = []
    @State private var showEmailPreview = false
    @State private var googleSheetsURL: String = ""
    @State private var importMethod: ImportMethod = .file
    
    enum ImportMethod {
        case file
        case googleSheets
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Import Email List")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Import email addresses from a file or Google Sheets to send event invitations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Import Method Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Import Method")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Picker("Import Method", selection: $importMethod) {
                            Text("Upload File").tag(ImportMethod.file)
                            Text("Google Sheets").tag(ImportMethod.googleSheets)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }
                    
                    // Conditional Import Section
                    if importMethod == .googleSheets {
                        // Google Sheets Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Google Sheets Link")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 16) {
                                // Instructions
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("How to use:")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        InstructionRow(number: 1, text: "Open your Google Sheet")
                                        InstructionRow(number: 2, text: "Click Share → Anyone with link can view")
                                        InstructionRow(number: 3, text: "Copy the share link")
                                        InstructionRow(number: 4, text: "Paste the link below")
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                // URL Input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Sheet Link")
                                        .font(.system(size: 14, weight: .medium))
                                    
                                    TextField("Link to the google sheets", text: $googleSheetsURL)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .autocapitalization(.none)
                                        .keyboardType(.URL)
                                }
                                
                                // Import Button
                                Button(action: importFromGoogleSheets) {
                                    HStack {
                                        if isProcessing {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(.white)
                                        }
                                        
                                        Text(isProcessing ? "Importing..." : "Import from Google Sheets")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(googleSheetsURL.isEmpty ? Color.gray : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(googleSheetsURL.isEmpty || isProcessing)
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        // File Upload Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Upload File")
                                .font(.headline)
                                .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            // Upload Button
                            Button(action: {
                                showDocumentPicker = true
                            }) {
                                VStack(spacing: 16) {
                                    // Upload Icon
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "doc.badge.plus")
                                            .font(.system(size: 32, weight: .medium))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Text("Choose File")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.blue)
                                        
                                        Text("CSV files (.csv format)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                        .background(Color.blue.opacity(0.05))
                                )
                                .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // File Requirements
                            VStack(alignment: .leading, spacing: 8) {
                                Text("File Requirements:")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                    VStack(alignment: .leading, spacing: 4) {
                                        RequirementRow(text: "First column should contain email addresses")
                                        RequirementRow(text: "Supported format: .csv only")
                                        RequirementRow(text: "Convert to CSV: File → Download as CSV")
                                        RequirementRow(text: "Maximum file size: 10MB")
                                        RequirementRow(text: "Up to 500 email addresses per batch")
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Selected File Info
                    if let file = selectedFile {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Selected File")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(file.lastPathComponent)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text("Ready to process")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                                
                                Button("Remove") {
                                    selectedFile = nil
                                    importedEmails = []
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Process Button
                    if selectedFile != nil {
                        VStack(spacing: 16) {
                            Button(action: processFile) {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                    }
                                    
                                    Text(isProcessing ? "Processing..." : "Process File")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing)
                            .padding(.horizontal)
                            
                            if !importedEmails.isEmpty {
                                Button(action: {
                                    showEmailPreview = true
                                }) {
                                    HStack {
                                        Image(systemName: "eye.fill")
                                        Text("Preview \(importedEmails.count) Email\(importedEmails.count == 1 ? "" : "s")")
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Import List")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(selectedFile: $selectedFile)
        }
        .sheet(isPresented: $showEmailPreview) {
            EmailPreviewSheet(emails: importedEmails, event: event)
        }
        .alert("Import Result", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func processFile() {
        guard let file = selectedFile else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Start accessing security-scoped resource
                guard file.startAccessingSecurityScopedResource() else {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.alertMessage = "Unable to access the selected file. Please try again."
                        self.showAlert = true
                    }
                    return
                }
                
                defer {
                    file.stopAccessingSecurityScopedResource()
                }
                
                // Read file data
                let fileData = try Data(contentsOf: file)
                
                // Determine file type and parse accordingly
                let fileExtension = file.pathExtension.lowercased()
                var extractedEmails: [String] = []
                
                if fileExtension == "csv" {
                    // Parse CSV file
                    extractedEmails = self.parseCSV(data: fileData)
                } else if fileExtension == "xlsx" || fileExtension == "xls" {
                    // For Excel files, instruct user to save as CSV
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.alertMessage = "Excel files must be saved as CSV format.\n\nTo convert:\n1. Open your file\n2. File → Download as CSV\n3. Upload the CSV file"
                        self.showAlert = true
                    }
                    return
                } else {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.alertMessage = "Unsupported file format. Please use CSV format."
                        self.showAlert = true
                    }
                    return
                }
                
                // Validate emails
                let validEmails = extractedEmails.filter { self.isValidEmail($0) }
                let uniqueEmails = Array(Set(validEmails)) // Remove duplicates
                
                DispatchQueue.main.async {
                    self.importedEmails = uniqueEmails
                    self.isProcessing = false
                    
                    if uniqueEmails.isEmpty {
                        self.alertMessage = "No valid email addresses found in the file. Please check the file format."
                    } else {
                        let duplicateCount = validEmails.count - uniqueEmails.count
                        var message = "Successfully imported \(uniqueEmails.count) email address\(uniqueEmails.count == 1 ? "" : "es")."
                        if duplicateCount > 0 {
                            message += " (\(duplicateCount) duplicate\(duplicateCount == 1 ? "" : "s") removed)"
                        }
                        self.alertMessage = message
                    }
                    self.showAlert = true
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.alertMessage = "Error reading file: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    private func parseCSV(data: Data) -> [String] {
        guard let content = String(data: data, encoding: .utf8) else {
            return []
        }
        
        var emails: [String] = []
        let lines = content.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            // Skip empty lines
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty {
                continue
            }
            
            // Parse CSV line (handle quotes and commas)
            let values = parseCSVLine(trimmedLine)
            
            // Skip if no values parsed
            guard !values.isEmpty else { continue }
            
            // Skip header row if it looks like a header
            if index == 0 {
                let lowercased = values[0].lowercased()
                if lowercased.contains("email") || lowercased.contains("mail") || lowercased == "e-mail" {
                    continue
                }
            }
            
            // Extract email from first column (already checked !values.isEmpty above)
            let potentialEmail = values[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if !potentialEmail.isEmpty {
                emails.append(potentialEmail)
            }
        }
        
        return emails
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                values.append(currentValue)
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }
        
        // Add the last value
        values.append(currentValue)
        
        return values.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func importFromGoogleSheets() {
        guard !googleSheetsURL.isEmpty else { return }
        
        isProcessing = true
        
        // Extract sheet ID from Google Sheets URL
        guard let sheetID = extractSheetID(from: googleSheetsURL) else {
            isProcessing = false
            alertMessage = "Invalid Google Sheets URL. Please check the link and try again."
            showAlert = true
            return
        }
        
        // Convert Google Sheets to CSV export URL
        let csvExportURL = "https://docs.google.com/spreadsheets/d/\(sheetID)/export?format=csv"
        
        // Fetch data from Google Sheets
        guard let url = URL(string: csvExportURL) else {
            isProcessing = false
            alertMessage = "Invalid URL format."
            showAlert = true
            return
        }
        
        URLSession.shared.dataTask(with: url) { [self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.isProcessing = false
                    self.alertMessage = "Failed to fetch Google Sheets: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                guard let data = data else {
                    self.isProcessing = false
                    self.alertMessage = "No data received from Google Sheets."
                    self.showAlert = true
                    return
                }
                
                // Parse CSV data
                let extractedEmails = self.parseCSV(data: data)
                
                // Validate emails
                let validEmails = extractedEmails.filter { self.isValidEmail($0) }
                let uniqueEmails = Array(Set(validEmails))
                
                self.importedEmails = uniqueEmails
                self.isProcessing = false
                
                                if uniqueEmails.isEmpty {
                                    self.alertMessage = "No valid email addresses found in Google Sheet. Make sure emails are in the first column (Column A)."
                                    self.showAlert = true
                                } else {
                                    // Success - show preview
                                    self.showEmailPreview = true
                                }
            }
        }.resume()
    }
    
    private func extractSheetID(from urlString: String) -> String? {
        // Extract sheet ID from various Google Sheets URL formats
        let patterns = [
            "/spreadsheets/d/([a-zA-Z0-9-_]+)",
            "/d/([a-zA-Z0-9-_]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)),
               let range = Range(match.range(at: 1), in: urlString) {
                return String(urlString[range])
            }
        }
        
        return nil
    }
    
}

// MARK: - Instruction Row for Google Sheets
struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Requirement Row
struct RequirementRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFile: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.commaSeparatedText])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                return
            }
            
            parent.selectedFile = url
            parent.dismiss()
        }
    }
}

// MARK: - Email Preview Sheet
struct EmailPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let emails: [String]
    let event: Event
    
    @State private var isSending = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Preview")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Review the email addresses before sending invitations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                
                // Email List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(emails, id: \.self) { email in
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                
                                Text(email)
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                
                // Send Button
                VStack(spacing: 12) {
                    Button(action: sendInvitations) {
                        HStack {
                            if isSending {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            
                            Text(isSending ? "Sending..." : "Send Invitations")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSending)
                    
                    Text("Invitations will be sent to \(emails.count) email addresses")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Invitations Sent", isPresented: $showAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func sendInvitations() {
        isSending = true
        
        // Prepare event data for the Cloud Function
        let eventData: [String: Any] = [
            "eventID": event.eventID,
            "name": event.name,
            "fromDate": event.from.timeIntervalSince1970 * 1000, // Convert to milliseconds
            "toDate": event.to.timeIntervalSince1970 * 1000,
            "venueName": event.venueName,
            "city": event.city ?? "",
            "state": event.state ?? "",
            "ticketPrice": event.ticketPrice ?? 0,
            "ticketTypes": event.ticketTypes?.map { ticketType in
                return [
                    "name": ticketType.name,
                    "price": ticketType.price
                ]
            } ?? [],
            "eventBannerUrl": event.eventBannerUrl,
            "hostID": event.hostIDs.first ?? ""
        ]
        
        // Call Firebase Cloud Function
        let functions = Functions.functions()
        functions.httpsCallable("sendEventInvitationEmails").call([
            "emails": emails,
            "eventData": eventData
        ]) { result, error in
            DispatchQueue.main.async {
                self.isSending = false
                
                if let error = error as NSError? {
                    if error.domain == FunctionsErrorDomain {
                        let code = FunctionsErrorCode(rawValue: error.code)
                        let message = error.localizedDescription
                        let details = error.userInfo[FunctionsErrorDetailsKey]
                        
                        print("❌ Cloud Function Error:")
                        print("Code: \(String(describing: code))")
                        print("Message: \(message)")
                        print("Details: \(String(describing: details))")
                        
                        self.alertMessage = "Failed to send invitations: \(message)"
                    } else {
                        self.alertMessage = "Failed to send invitations: \(error.localizedDescription)"
                    }
                    self.showAlert = true
                    return
                }
                
                // Parse the response
                if let data = result?.data as? [String: Any],
                   let success = data["success"] as? Bool {
                    
                    if success {
                        if let results = data["results"] as? [String: Any],
                           let successful = results["successful"] as? Int,
                           let failed = results["failed"] as? Int {
                            
                            var message = "Successfully sent \(successful) invitation\(successful == 1 ? "" : "s")!"
                            if failed > 0 {
                                message += "\n\(failed) email\(failed == 1 ? "" : "s") failed to send."
                            }
                            self.alertMessage = message
                        } else {
                            self.alertMessage = "Invitations sent successfully!"
                        }
                    } else {
                        let errorMsg = data["error"] as? String ?? "Unknown error"
                        self.alertMessage = "Failed to send invitations: \(errorMsg)"
                    }
                } else {
                    self.alertMessage = "Invitations sent successfully!"
                }
                
                self.showAlert = true
            }
        }
    }
}

// MARK: - Preview
struct EventPropertiesView_Previews: PreviewProvider {
    static var previews: some View {
        EventPropertiesView(event: Event())
            .preferredColorScheme(.dark)
    }
}

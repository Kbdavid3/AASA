import SwiftUI
import FirebaseFirestore
import Foundation
import FirebaseMessaging

struct SendNotificationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentation
    
    let event: Event
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    @State private var title: String = ""
    @State private var message: String = ""
    @State private var selectedRecipientType: RecipientType = .eventJoinees
    @State private var scheduleForLater: Bool = false
    @State private var scheduledDate: Date = Date() // Default to current time
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var selectedUserIDs: [String] = []
    @State private var showUserSelection: Bool = false
    @State private var includeHostInNotifications: Bool = false
    
    enum RecipientType: String, CaseIterable {
        case eventJoinees = "Event Joinees Only"
        case specificUsers = "Specific Users"
        
        var description: String {
            switch self {
            case .eventJoinees:
                return "Send to people who have shown interest in the event"
            case .specificUsers:
                return "Send to specific users you select"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Spacer()
                    
                    Text("Send Notification")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // Title Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            TextField("Enter notification title", text: $title)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color.secondaryBgColor)
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .disableAutocorrection(false)
                                .autocapitalization(.words)
                        }
                        
                        // Message Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 0) {
                                // Use a more Xcode-debugging-friendly approach
                                TextField("Enter your message", text: $message, axis: .vertical)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.secondaryBgColor)
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                    .lineLimit(4...8)
                                    .disableAutocorrection(false)
                                    .autocapitalization(.sentences)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        // Dismiss keyboard when done
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }
                            }
                        }
                        
                        // Send To Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Send To")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                ForEach(RecipientType.allCases, id: \.self) { type in
                                    RecipientOptionView(
                                        type: type,
                                        isSelected: selectedRecipientType == type,
                                        onTap: {
                                            selectedRecipientType = type
                                        }
                                    )
                                }
                            }
                            
                            // Show specific users selection if that option is selected
                            if selectedRecipientType == .specificUsers {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Select Users")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Button(action: {
                                        showUserSelection = true
                                    }) {
                                        HStack {
                                            Image(systemName: "person.2")
                                                .foregroundColor(.blue)
                                            Text(selectedUserIDs.isEmpty ? "Choose specific users" : "\(selectedUserIDs.count) user\(selectedUserIDs.count == 1 ? "" : "s") selected")
                                                .foregroundColor(.blue)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.secondaryBgColor)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.top, 8)
                            }
                            
                            // Include Host Option (only show for event joinees)
                            if selectedRecipientType == .eventJoinees {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Include Host in Notifications")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: $includeHostInNotifications)
                                            .toggleStyle(CustomToggleStyle())
                                    }
                                    
                                    Text("Send notification to event host even if they're also a joinee")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        // Schedule for Later Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Schedule for Later")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $scheduleForLater)
                                    .toggleStyle(CustomToggleStyle())
                            }
                            
                            
                            
                            if scheduleForLater {
                                VStack(alignment: .leading, spacing: 8) {
                                    DatePicker("Scheduled Date", selection: $scheduledDate, in: Date()...)
                                        .datePickerStyle(CompactDatePickerStyle())
                                        .foregroundColor(.white)
                                    
                                    Text("Scheduled for: \(scheduledDate, formatter: dateFormatter)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                
                // Send Button
                VStack {
                    Button(action: sendNotification) {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane")
                                .foregroundColor(.white)
                            
                            Text("Send Notification")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(title.isEmpty || message.isEmpty || isLoading)
                    .opacity((title.isEmpty || message.isEmpty || isLoading) ? 0.6 : 1.0)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .alert("Notification", isPresented: $showAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    presentation.wrappedValue.dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showUserSelection) {
            UserSelectionView(selectedUserIDs: $selectedUserIDs, event: event)
        }
        .onAppear {
            // Auto-fill the title with "Event: (Event Name)"
            if title.isEmpty {
                title = "Event: \(event.name)"
            }
        }
    }
    
    private func sendNotification() {
        guard !title.isEmpty && !message.isEmpty else { return }
        
        // Check if specific users is selected but no users are chosen
        if selectedRecipientType == .specificUsers && selectedUserIDs.isEmpty {
            alertMessage = "Please select specific users to send the notification to."
            showAlert = true
            return
        }
        
        isLoading = true
        
        let notificationData: [String: Any] = [
            "eventID": event.eventID,
            "title": title,
            "message": message,
            "recipientType": selectedRecipientType.rawValue,
            "scheduledForLater": scheduleForLater,
            "scheduledDate": scheduleForLater ? scheduledDate : Date(),
            "createdAt": Date(),
            "hostID": UserManager.shared.currentUserID ?? "",
            "specificUserIDs": selectedUserIDs
        ]
        
        let db = Firestore.firestore()
        
        if scheduleForLater {
            print("📅 Scheduling notification for: \(scheduledDate)")
            print("📅 Current time: \(Date())")
            print("📅 Target audience: \(selectedRecipientType.rawValue)")
            
            // Create scheduled notification using EnhancedNotificationManager
            let scheduledNotification = ScheduledNotification(
                notificationID: UUID().uuidString,
                eventID: event.eventID,
                hostID: UserManager.shared.currentUserID ?? "",
                title: title,
                body: message,
                scheduledFor: scheduledDate,
                targetAudience: selectedRecipientType == .eventJoinees ? .eventJoinees : .specificUsers,
                targetUserIDs: selectedRecipientType == .specificUsers ? selectedUserIDs : nil
            )
            
            print("📅 Created scheduled notification: \(scheduledNotification)")
            
            // Save to Firestore
            do {
                let data = try JSONEncoder().encode(scheduledNotification)
                let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                
                // Convert Date to Timestamp for Firestore
                var firestoreDict = dict
                firestoreDict["scheduledFor"] = Timestamp(date: scheduledDate)
                firestoreDict["createdAt"] = Timestamp(date: Date())
                
                print("📅 Saving to Firestore with data: \(firestoreDict)")
                db.collection("scheduledNotifications").addDocument(data: firestoreDict) { error in
                    DispatchQueue.main.async {
                        isLoading = false
                        if let error = error {
                            print("❌ Failed to schedule notification: \(error.localizedDescription)")
                            alertMessage = "Failed to schedule notification: \(error.localizedDescription)"
                        } else {
                            print("✅ Notification scheduled successfully!")
                            alertMessage = "Notification scheduled successfully!"
                        }
                        showAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    alertMessage = "Failed to schedule notification: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        } else {
            // Send immediate notification
            sendImmediateNotification(notificationData: notificationData)
        }
    }
    
    private func sendImmediateNotification(notificationData: [String: Any]) {
        print("🔔 sendImmediateNotification called with data: \(notificationData)")
        
        guard let hostID = UserManager.shared.currentUserID else {
            print("❌ User not authenticated")
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = "Failed to send notification: User not authenticated"
                showAlert = true
            }
            return
        }
        
        print("✅ Host ID: \(hostID)")
        
        // Get target users based on recipient type
        getTargetUsers { targetUserIDs in
            print("📊 Target users count: \(targetUserIDs.count)")
            print("📊 Target users: \(targetUserIDs)")
            
            // Add a small delay to ensure UI updates are processed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("🔄 Processing notifications after UI delay")
            }
            
            guard !targetUserIDs.isEmpty else {
                print("❌ No target users found")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertMessage = "No users found to send notification to"
                    self.showAlert = true
                }
                return
            }
            
            var successCount = 0
            var processedCount = 0
            
            // Determine target users based on includeHostInNotifications setting
            let targetUsers: [String]
            if selectedRecipientType == .eventJoinees && includeHostInNotifications {
                // Include host if they're also a joinee
                targetUsers = targetUserIDs
                print("📤 Including host in notifications (host is also a joinee)")
            } else {
                // Exclude host from notifications
                targetUsers = targetUserIDs.filter { $0 != hostID }
                print("📤 Excluding host from notifications")
            }
            
            // If no users to send to, show success message
            if targetUsers.isEmpty {
                print("📤 No users to send notification to")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertMessage = "No users to send notification to"
                    self.showAlert = true
                }
                return
            }
            
            for userID in targetUsers {
                print("📤 Creating notification for user: \(userID)")
                
                let notification = EnhancedNotification(
                    notificationID: UUID().uuidString,
                    type: .customHostNotification,
                    title: notificationData["title"] as? String ?? "",
                    body: notificationData["message"] as? String ?? "",
                    senderID: hostID,
                    receiverID: userID,
                    eventID: notificationData["eventID"] as? String
                )
                
                EnhancedNotificationManager.shared.createAndSendNotification(notification) { success in
                    print("📤 Notification result for user \(userID): \(success)")
                    DispatchQueue.main.async {
                        processedCount += 1
                        if success {
                            successCount += 1
                            print("✅ Success count: \(successCount)")
                        } else {
                            print("❌ Failed to send notification to user: \(userID)")
                        }
                        
                        // Check if all notifications have been processed
                        if processedCount == targetUsers.count {
                            print("🎉 All notifications processed. Success: \(successCount)/\(targetUsers.count)")
                            print("📊 Final results: \(successCount) successful, \(targetUsers.count - successCount) failed")
                            self.isLoading = false
                            if successCount > 0 {
                                self.alertMessage = "Notification sent to \(successCount) user\(successCount == 1 ? "" : "s") successfully!"
                            } else {
                                self.alertMessage = "Failed to send notification to any users"
                            }
                            self.showAlert = true
                        }
                    }
                }
            }
        }
    }
    
    private func getTargetUsers(completion: @escaping ([String]) -> Void) {
        print("🔍 Getting target users for type: \(selectedRecipientType.rawValue)")
        
        switch selectedRecipientType {
        case .eventJoinees:
            print("🔍 Getting event joinees for event: \(event.eventID)")
            // Get event joinees
            EventManager.shared.getEvent(with: event.eventID) { event in
                guard let event = event else {
                    print("❌ Event not found: \(self.event.eventID)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.alertMessage = "Event not found"
                        self.showAlert = true
                    }
                    completion([])
                    return
                }
                print("✅ Found event with \(event.interestedUserIDs.count) interested users")
                print("📋 Interested user IDs: \(event.interestedUserIDs)")
                
                // Check if there are any interested users
                if event.interestedUserIDs.isEmpty {
                    print("⚠️ No interested users found for this event")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.alertMessage = "No users are interested in this event"
                        self.showAlert = true
                    }
                }
                
                completion(event.interestedUserIDs)
            }
            
        case .specificUsers:
            print("🔍 Using selected specific users: \(selectedUserIDs.count) users")
            if selectedUserIDs.isEmpty {
                print("⚠️ No specific users selected")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertMessage = "Please select users to send notification to"
                    self.showAlert = true
                }
            }
            // Use selected specific users
            completion(selectedUserIDs)
        }
        
    }
    
    struct RecipientOptionView: View {
        let type: SendNotificationView.RecipientType
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Radio button
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                            .frame(width: 20, height: 20)
                        
                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(type.description)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    struct CustomTextFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding()
                .background(Color.secondaryBgColor)
                .cornerRadius(12)
                .foregroundColor(.white)
        }
    }
    
    struct CustomToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.label
                Spacer()
                Rectangle()
                    .fill(configuration.isOn ? Color.blue : Color.gray)
                    .frame(width: 51, height: 31)
                    .cornerRadius(15.5)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 27, height: 27)
                            .offset(x: configuration.isOn ? 10 : -10)
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            configuration.isOn.toggle()
                        }
                    }
            }
        }
    }
    
    struct SendNotificationView_Previews: PreviewProvider {
        static var previews: some View {
            SendNotificationView(event: Event())
                .preferredColorScheme(.dark)
        }
    }
}
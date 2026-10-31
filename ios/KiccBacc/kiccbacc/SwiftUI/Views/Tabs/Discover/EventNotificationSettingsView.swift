//
//  EventNotificationSettingsView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

struct EventNotificationSettingsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentation
    
    let event: Event
    let host: User
    
    @StateObject private var viewModel = EventNotificationSettingsViewModel()
    
    @State private var showCustomNotificationSheet = false
    @State private var showScheduledNotificationSheet = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notification Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Control how and when notifications are sent for '\(event.name)'")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Notification Type Toggles
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Notification Types")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(NotificationType.allCases, id: \.self) { notificationType in
                                NotificationTypeToggleRow(
                                    notificationType: notificationType,
                                    isEnabled: viewModel.isNotificationTypeEnabled(notificationType),
                                    onToggle: { isEnabled in
                                        viewModel.toggleNotificationType(notificationType, isEnabled: isEnabled)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Audience Settings
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Default Audience")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Picker("Target Audience", selection: $viewModel.defaultAudience) {
                            ForEach(NotificationAudience.allCases, id: \.self) { audience in
                                Text(audience.displayName)
                                    .tag(audience)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        Text(viewModel.defaultAudience.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    
                    // Special Features
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Special Features")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            Toggle("Auto Milestone Notifications", isOn: $viewModel.autoMilestoneNotifications)
                                .padding(.horizontal)
                            
                            Toggle("Story Upload Prompts", isOn: $viewModel.storyUploadPrompts)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button {
                            showCustomNotificationSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "bell.badge")
                                Text("Send Custom Notification")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        Button {
                            showScheduledNotificationSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "clock.badge")
                                Text("Schedule Notification")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        Button {
                            viewModel.saveSettings { success in
                                if success {
                                    alertMessage = "Settings saved successfully!"
                                } else {
                                    alertMessage = "Failed to save settings. Please try again."
                                }
                                showAlert = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Save Settings")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Scheduled Notifications List
                    if !viewModel.scheduledNotifications.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Scheduled Notifications")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.scheduledNotifications) { notification in
                                ScheduledNotificationRow(notification: notification) {
                                    viewModel.deleteScheduledNotification(notification)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        presentation.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadSettings(eventID: event.eventID, hostID: host.userID)
            viewModel.loadScheduledNotifications(eventID: event.eventID)
        }
        .sheet(isPresented: $showCustomNotificationSheet) {
            CustomNotificationSheet(
                event: event,
                host: host,
                defaultAudience: viewModel.defaultAudience
            )
        }
        .sheet(isPresented: $showScheduledNotificationSheet) {
            ScheduledNotificationSheet(
                event: event,
                host: host,
                defaultAudience: viewModel.defaultAudience
            )
        }
        .alert("Notification Settings", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Notification Type Toggle Row

struct NotificationTypeToggleRow: View {
    let notificationType: NotificationType
    let isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(notificationType.displayName)
                    .font(.system(size: 16, weight: .medium))
                
                Text(notificationType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Scheduled Notification Row

struct ScheduledNotificationRow: View {
    let notification: ScheduledNotification
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(notification.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("Scheduled for: \(notification.scheduledFor.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Custom Notification Sheet

struct CustomNotificationSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let event: Event
    let host: User
    let defaultAudience: NotificationAudience
    
    @State private var title = ""
    @State private var body = ""
    @State private var selectedAudience: NotificationAudience
    @State private var isLoading = false
    
    init(event: Event, host: User, defaultAudience: NotificationAudience) {
        self.event = event
        self.host = host
        self.defaultAudience = defaultAudience
        self._selectedAudience = State(initialValue: defaultAudience)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notification Content") {
                    TextField("Title", text: $title)
                    TextField("Message", text: $body, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Target Audience") {
                    Picker("Audience", selection: $selectedAudience) {
                        ForEach(NotificationAudience.allCases, id: \.self) { audience in
                            Text(audience.displayName)
                                .tag(audience)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text(selectedAudience.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button {
                        sendNotification()
                    } label: {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Sending...")
                            }
                        } else {
                            Text("Send Notification")
                        }
                    }
                    .disabled(title.isEmpty || body.isEmpty || isLoading)
                }
            }
            .navigationTitle("Custom Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Auto-fill the title with "Event: (Event Name)"
                if title.isEmpty {
                    title = "Event: \(event.name)"
                }
            }
        }
    }
    
    private func sendNotification() {
        isLoading = true
        
        EnhancedNotificationManager.shared.sendImmediateHostNotification(
            title: title,
            body: body,
            eventID: event.eventID,
            hostID: host.userID,
            targetAudience: selectedAudience
        ) { success in
            isLoading = false
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Scheduled Notification Sheet

struct ScheduledNotificationSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let event: Event
    let host: User
    let defaultAudience: NotificationAudience
    
    @State private var title = ""
    @State private var body = ""
    @State private var selectedAudience: NotificationAudience
    @State private var scheduledDate = Date()
    @State private var isLoading = false
    
    init(event: Event, host: User, defaultAudience: NotificationAudience) {
        self.event = event
        self.host = host
        self.defaultAudience = defaultAudience
        self._selectedAudience = State(initialValue: defaultAudience)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notification Content") {
                    TextField("Title", text: $title)
                    TextField("Message", text: $body, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Schedule") {
                    DatePicker("Send At", selection: $scheduledDate, in: Date()...)
                }
                
                Section("Target Audience") {
                    Picker("Audience", selection: $selectedAudience) {
                        ForEach(NotificationAudience.allCases, id: \.self) { audience in
                            Text(audience.displayName)
                                .tag(audience)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text(selectedAudience.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button {
                        scheduleNotification()
                    } label: {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Scheduling...")
                            }
                        } else {
                            Text("Schedule Notification")
                        }
                    }
                    .disabled(title.isEmpty || body.isEmpty || isLoading)
                }
            }
            .navigationTitle("Schedule Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Auto-fill the title with "Event: (Event Name)"
                if title.isEmpty {
                    title = "Event: \(event.name)"
                }
            }
        }
    }
    
    private func scheduleNotification() {
        isLoading = true
        
        let scheduledNotification = ScheduledNotification(
            notificationID: UUID().uuidString,
            eventID: event.eventID,
            hostID: host.userID,
            title: title,
            body: body,
            scheduledFor: scheduledDate,
            targetAudience: selectedAudience
        )
        
        EnhancedNotificationManager.shared.scheduleHostNotification(scheduledNotification) { success in
            isLoading = false
            if success {
                dismiss()
            }
        }
    }
}

struct EventNotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        EventNotificationSettingsView(
            event: Event(),
            host: User()
        )
    }
}

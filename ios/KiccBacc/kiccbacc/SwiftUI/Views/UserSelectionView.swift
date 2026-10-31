import SwiftUI
import FirebaseFirestore

struct UserSelectionView: View {
    @Environment(\.presentationMode) private var presentation
    
    @Binding var selectedUserIDs: [String]
    let event: Event? // Optional event for joinees section
    
    @State private var eventJoinees: [User] = []
    @State private var allUsers: [User] = []
    @State private var searchResults: [User] = []
    @State private var isLoadingJoinees: Bool = true
    @State private var isLoadingMoreUsers: Bool = false
    @State private var isSearching: Bool = false
    @State private var searchText: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    // Pagination for all users
    @State private var currentPage: Int = 0
    @State private var hasMoreUsers: Bool = true
    @State private var lastDocument: DocumentSnapshot?
    private let pageSize: Int = 10
    
    // Section selection
    @State private var selectedSection: UserSection = .eventJoinees
    
    enum UserSection: String, CaseIterable {
        case eventJoinees = "Event Joinees"
        case allUsers = "All Users"
        
        var icon: String {
            switch self {
            case .eventJoinees: return "person.2.fill"
            case .allUsers: return "person.3.fill"
            }
        }
    }
    
    var displayedUsers: [User] {
        if !searchText.isEmpty {
            return searchResults
        } else if selectedSection == .eventJoinees {
            return eventJoinees
        } else {
            return allUsers
        }
    }
    
    var isLoading: Bool {
        if !searchText.isEmpty {
            return isSearching
        } else if selectedSection == .eventJoinees {
            return isLoadingJoinees
        } else {
            return false // We don't show loading for all users section initially
        }
    }
    
    var body: some View {
        ZStack {
            Color.bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Spacer()
                    
                    Text("Select Users")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Done") {
                        presentation.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search Firebase users by name or username", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .onChange(of: searchText) { newValue in
                            handleSearchChange(newValue)
                        }
                    
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.secondaryBgColor)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Section Selector
                if event != nil {
                    HStack(spacing: 0) {
                        ForEach(UserSection.allCases, id: \.self) { section in
                            Button(action: {
                                selectedSection = section
                                if section == .allUsers && allUsers.isEmpty {
                                    loadAllUsers()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: section.icon)
                                        .font(.system(size: 14))
                                    
                                    Text(section.rawValue)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(selectedSection == section ? .white : .gray)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    selectedSection == section ? Color.blue : Color.clear
                                )
                            }
                        }
                    }
                    .background(Color.secondaryBgColor)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
                
                // Selected Users Count
                if !selectedUserIDs.isEmpty {
                    HStack {
                        Text("\(selectedUserIDs.count) user\(selectedUserIDs.count == 1 ? "" : "s") selected")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button("Clear All") {
                            selectedUserIDs.removeAll()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
                
                // Users List
                if isLoading {
                    Spacer()
                    ProgressView()
                        .foregroundColor(.white)
                    Spacer()
                } else if displayedUsers.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: selectedSection == .eventJoinees ? "person.2" : "person.3",
                        title: searchText.isEmpty ? "No users found" : "No users found",
                        subtitle: searchText.isEmpty ? "Unable to load users" : "Try searching with different terms"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(displayedUsers, id: \.userID) { user in
                                UserRowView(
                                    user: user,
                                    isSelected: selectedUserIDs.contains(user.userID),
                                    onToggle: { isSelected in
                                        toggleUserSelection(user.userID, isSelected: isSelected)
                                    }
                                )
                            }
                            
                            // Load more button for pagination (only in all users section, not searching)
                            if selectedSection == .allUsers && hasMoreUsers && searchText.isEmpty {
                                Button(action: loadMoreUsers) {
                                    HStack {
                                        if isLoadingMoreUsers {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "arrow.down.circle")
                                        }
                                        Text(isLoadingMoreUsers ? "Loading..." : "Load More Users")
                                    }
                                    .foregroundColor(.blue)
                                    .padding()
                                }
                                .disabled(isLoadingMoreUsers)
                            }
                        }
                        .padding(.top, 12)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadEventJoinees()
            if event == nil {
                // If no event provided, default to all users
                selectedSection = .allUsers
                loadAllUsers()
            }
        }
    }
    
    private func toggleUserSelection(_ userID: String, isSelected: Bool) {
        if isSelected {
            if !selectedUserIDs.contains(userID) {
                selectedUserIDs.append(userID)
            }
        } else {
            selectedUserIDs.removeAll { $0 == userID }
        }
    }
    
    private func handleSearchChange(_ newValue: String) {
        // Cancel any pending search
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        if newValue.isEmpty {
            isSearching = false
            searchResults.removeAll()
            return
        }
        
        // Only search if query is at least 2 characters
        guard newValue.count >= 2 else {
            searchResults.removeAll()
            isSearching = false
            return
        }
        
        // Optimized debouncing - shorter delay for better responsiveness
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Double-check the search text hasn't changed
            guard self.searchText == newValue else { return }
            
            // Only perform search if not already searching
            guard !self.isSearching else { return }
            
            self.performFirebaseSearch(query: newValue)
        }
    }
    
    private func performFirebaseSearch(query: String) {
        // Prevent multiple simultaneous searches
        guard !isSearching else { return }
        
        isSearching = true
        
        let db = Firestore.firestore()
        
        // Search by name using range queries
        let nameQuery = db.collection("users")
            .whereField("fullName", isGreaterThanOrEqualTo: query)
            .whereField("fullName", isLessThan: query + "\u{f8ff}")
            .limit(to: 10)
        
        // Search by username using range queries
        let usernameQuery = db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: query.lowercased())
            .whereField("username", isLessThan: query.lowercased() + "\u{f8ff}")
            .limit(to: 10)
        
        let dispatchGroup = DispatchGroup()
        var foundUsers: [User] = []
        
        // Search by name
        dispatchGroup.enter()
        nameQuery.getDocuments { snapshot, error in
            defer { dispatchGroup.leave() }
            
            if let error = error {
                print("Name search error: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            let users = documents.compactMap { document -> User? in
                do {
                    return try document.data(as: User.self)
                } catch {
                    print("Error parsing user: \(error)")
                    return nil
                }
            }.filter { user in
                user.fullName.localizedCaseInsensitiveContains(query)
            }
            
            foundUsers.append(contentsOf: users)
        }
        
        // Search by username
        dispatchGroup.enter()
        usernameQuery.getDocuments { snapshot, error in
            defer { dispatchGroup.leave() }
            
            if let error = error {
                print("Username search error: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            let users = documents.compactMap { document -> User? in
                do {
                    return try document.data(as: User.self)
                } catch {
                    print("Error parsing user: \(error)")
                    return nil
                }
            }.filter { user in
                user.username.localizedCaseInsensitiveContains(query)
            }
            
            foundUsers.append(contentsOf: users)
        }
        
        dispatchGroup.notify(queue: .main) {
            self.isSearching = false
            
            // Remove duplicates based on userID
            let uniqueUsers = Array(Set(foundUsers.map { $0.userID }))
                .compactMap { userID in
                    foundUsers.first { $0.userID == userID }
                }
            
            // Sort by relevance
            let sortedUsers = uniqueUsers.sorted { user1, user2 in
                let name1Match = user1.fullName.localizedCaseInsensitiveContains(query)
                let name2Match = user2.fullName.localizedCaseInsensitiveContains(query)
                
                if name1Match && !name2Match {
                    return true
                } else if !name1Match && name2Match {
                    return false
                } else {
                    return user1.fullName < user2.fullName
                }
            }
            
            self.searchResults = sortedUsers
        }
    }
    
    private func loadEventJoinees() {
        guard let event = event else {
            isLoadingJoinees = false
            return
        }
        
        let db = Firestore.firestore()
        let joineeIDs = event.interestedUserIDs
        
        if joineeIDs.isEmpty {
            isLoadingJoinees = false
            return
        }
        
        // Load users in batches
        let batchSize = 10
        var loadedUsers: [User] = []
        let dispatchGroup = DispatchGroup()
        
        for i in stride(from: 0, to: joineeIDs.count, by: batchSize) {
            let endIndex = min(i + batchSize, joineeIDs.count)
            let batch = Array(joineeIDs[i..<endIndex])
            
            dispatchGroup.enter()
            
            db.collection("users")
                .whereField("userID", in: batch)
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("Error loading joinees batch: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    let users = documents.compactMap { document in
                        try? document.data(as: User.self)
                    }
                    
                    DispatchQueue.main.async {
                        loadedUsers.append(contentsOf: users)
                    }
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.eventJoinees = loadedUsers
            self.isLoadingJoinees = false
        }
    }
    
    private func loadAllUsers() {
        let db = Firestore.firestore()
        
        var query = db.collection("users")
            .limit(to: pageSize)
        
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query.getDocuments { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.alertMessage = "Failed to load users: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.alertMessage = "No users found"
                    self.showAlert = true
                    return
                }
                
                let newUsers = documents.compactMap { document in
                    try? document.data(as: User.self)
                }
                
                // Always append to existing users
                self.allUsers.append(contentsOf: newUsers)
                
                self.lastDocument = documents.last
                self.hasMoreUsers = documents.count == self.pageSize
                self.currentPage += 1
            }
        }
    }
    
    private func loadMoreUsers() {
        guard hasMoreUsers && !isLoadingMoreUsers else { return }
        
        isLoadingMoreUsers = true
        loadAllUsers()
        
        // Reset loading state after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoadingMoreUsers = false
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

struct UserRowView: View {
    let user: User
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack(spacing: 12) {
                // Profile Image
                if let pfpUrl = user.profileImageUrlString, let url = URL(string: pfpUrl) {
                    KBImage(url: url, resizeMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.appColor)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(user.getInitials())
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.fullName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("@\(user.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .background(Color.gray.opacity(0.3))
            .padding(.leading, 68)
    }
}

struct UserSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        UserSelectionView(selectedUserIDs: .constant([]), event: Event())
            .preferredColorScheme(.dark)
    }
}
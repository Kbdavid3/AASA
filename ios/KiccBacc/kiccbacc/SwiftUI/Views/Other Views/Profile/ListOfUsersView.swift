//
//  ListOfUsersView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//


import SwiftUI

enum UsersKind {
    case followers
    case following
    case interestedUsers
    case seenBy
}

extension UsersKind {
    var title: String {
        switch self {
        case .followers:
            return "Followers"
        case .following:
            return "Following"
        case .interestedUsers:
            return "Joined"
        case .seenBy:
            return "Story views"
        }
    }
}

struct ListOfUsersView: View {
    
    @Environment(\.presentationMode) private var presentation
    
    var userIDs: [String]?
    var usersKind: UsersKind
    var isHost: Bool
    var eventID: String
    
    @State private var users: [User]?
    @State private var isFetchingUsers: Bool = false
    
    @State private var alertItem: AlertItem?
    @State private var viewItem: ViewItem?
    @State private var viewControllerItem: UIKitViewControllerItem?
    
    var body: some View {
        CustomScrollView(navigationStyle: .dismissBack(title: usersKind.title), scrollViewData: {
            VStack(alignment: .leading, spacing: 0) {
                if let users = users {
                    VStack {
                        ForEach(users, id: \.userID) { user in
                            UserRow(user: user, isHost: isHost, eventID: eventID, usersKind: usersKind)
                        }
                    }
                    .padding()
                } else if isFetchingUsers {
                    ProgressView()
                } else {
                    Text("No user found.")
                }
            }
        }, alertItem: $alertItem, viewControllerItem: $viewControllerItem, viewItem: $viewItem)
            .onAppear {
                withAnimation { isFetchingUsers = true }
                
                self.users = nil
                
                guard let userIDs = userIDs else {return}
                var userIDsToFetch = userIDs
                
                if userIDsToFetch.count > 10 {
                    
                    guard userIDsToFetch.count > 0 else {return}
                    
                    for _ in userIDsToFetch {
                        
                        let userIDs = userIDsToFetch.count > 10 ? Array(userIDsToFetch.prefix(10)) : userIDsToFetch
                        guard userIDs.count > 0 else {return}
                        
                        if userIDsToFetch.count > 10 {
                          userIDsToFetch = Array(userIDsToFetch.dropFirst(10))
                        } else {
                            userIDsToFetch = []
                        }
                        
                        switch usersKind {
                        case .followers:
                            UserManager.shared.getAllFollowers(with: userIDs) { users in
                                // Safe unwrap and append
                                if let fetchedUsers = users {
                                    if (self.users?.count ?? 0) > 0 {
                                        self.users?.append(contentsOf: fetchedUsers)
                                    } else {
                                        self.users = fetchedUsers
                                    }
                                }
                                
                                withAnimation { self.isFetchingUsers = false }
                            }
                        case .following:
                            UserManager.shared.getAllFollowing(with: userIDs) { users in
                                // Safe unwrap and append
                                if let fetchedUsers = users {
                                    if (self.users?.count ?? 0) > 0 {
                                        self.users?.append(contentsOf: fetchedUsers)
                                    } else {
                                        self.users = fetchedUsers
                                    }
                                }
                                
                                withAnimation { self.isFetchingUsers = false }
                            }
                        case .interestedUsers, .seenBy:
                            UserManager.shared.getUsers(with: userIDs) { users in
                                // Safe unwrap and append
                                if let fetchedUsers = users {
                                    if (self.users?.count ?? 0) > 0 {
                                        self.users?.append(contentsOf: fetchedUsers)
                                    } else {
                                        self.users = fetchedUsers
                                    }
                                }
                                
                                withAnimation { self.isFetchingUsers = false }
                            }
                        }
                    }
                } else {
                    switch usersKind {
                    case .followers:
                        UserManager.shared.getAllFollowers(with: userIDsToFetch) { users in
                            self.users = users
                            withAnimation { self.isFetchingUsers = false }
                        }
                    case .following:
                        UserManager.shared.getAllFollowing(with: userIDsToFetch) { users in
                            self.users = users
                            withAnimation { self.isFetchingUsers = false }
                        }
                    case .interestedUsers, .seenBy:
                        UserManager.shared.getUsers(with: userIDsToFetch) { users in
                            self.users = users
                            withAnimation { self.isFetchingUsers = false }
                        }
                    }
                }
            }
    }
    
    private func getInt(count: Double) -> Int {
        
        let doubleValue : Double = count
        let val = Int(String(format:"%.f", doubleValue)) ?? -1
        
        if Double(val) < doubleValue, val != -1 {
            return val+1
        }
        
        return val
    }

    private struct UserRow: View {
        
        var user: User
        var isHost: Bool
        var eventID: String
        var usersKind: UsersKind
        
        @State private var isFollowing: Bool = false
        @State private var isRemoved: Bool = false
        
        var body: some View {
            HStack {
                NavigationLink {
                    UserProfileView(user: user)
                } label: {
                    PfpView(user: user, size: 50, isRound: true)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(user.fullName)
                            .font(.system(size: 17, weight: .bold, design: .default))
                        
                        Text("@\(user.username)")
                            .font(.system(size: 14, weight: .regular, design: .default))
                    }
                    .foregroundColor(.labelColor)
                }
                
                Spacer()
                
                if user.userID != UserManager.shared.currentUserID && usersKind != .interestedUsers {
                    Button {
                        if isHost {
                            EventManager.shared.removeUserInterestedIn(userID: user.userID, event: eventID) { success in
                                print("success")
                                withAnimation { self.isRemoved = true }
                            }
                        } else {
                            if isFollowing {
                                UserManager.shared.unFollow(userToUnFollow: user) { isUnFollowed in
                                    withAnimation { self.isFollowing = !isUnFollowed }
                                }
                            } else {
                                UserManager.shared.follow(userToFollow: user) { isFollowed in
                                    withAnimation { self.isFollowing = isFollowed }
                                }
                            }
                        }
                    } label: {
                        if isHost {
                            Text("Remove")
                                .padding(10)
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .if(true) { view in
                                    view
                                        .foregroundColor(.white)
                                        .background(Color.buttonBgColor)
                                }
                                .cornerRadius(10)
                                .showIf(!(isRemoved))
                        } else {
                            Text(isFollowing ? "Following" : "Follow")
                                .padding(10)
                                .if(!isFollowing) { view in
                                    view
                                        .foregroundColor(.white)
                                        .background(Color.buttonBgColor)
                                }
                                .cornerRadius(10)
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .if(isFollowing) { view in
                                    view
                                        .foregroundColor(.labelColor)
                                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.appColor, lineWidth: 1))
                                }
                        }
                    }
                    .buttonStyle(PlainButtonStyle()) // Prevent gesture interference
                    .contentShape(Rectangle()) // Ensure the entire button area is tappable
                }
            }
            .contentShape(Rectangle())
            .onAppear {
                // check if current user is following this user
                UserManager.shared.isFollowing(user: user) { isFollowing in
                    withAnimation { self.isFollowing = isFollowing }
                }
            }
        }
        
        
    }
}

//struct ListOfUsersView_Previews: PreviewProvider {
//    static var previews: some View {
//        ListOfUsersView(usersKind: .followers)
//    }
//}

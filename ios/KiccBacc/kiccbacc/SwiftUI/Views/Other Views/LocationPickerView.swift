import SwiftUI
import CoreLocation

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLocation: String
    
    @State private var searchText = ""
    @State private var searchResults: [String] = []
    @State private var isSearching = false
    
    // Sample cities for demonstration - in a real app, you'd use a location service API
    private let sampleCities = [
        "New York, NY", "Los Angeles, CA", "Chicago, IL", "Houston, TX", "Phoenix, AZ",
        "Philadelphia, PA", "San Antonio, TX", "San Diego, CA", "Dallas, TX", "San Jose, CA",
        "Austin, TX", "Jacksonville, FL", "Fort Worth, TX", "Columbus, OH", "Charlotte, NC",
        "San Francisco, CA", "Indianapolis, IN", "Seattle, WA", "Denver, CO", "Washington, DC",
        "Boston, MA", "El Paso, TX", "Nashville, TN", "Detroit, MI", "Oklahoma City, OK",
        "Portland, OR", "Las Vegas, NV", "Memphis, TN", "Louisville, KY", "Baltimore, MD",
        "Milwaukee, WI", "Albuquerque, NM", "Tucson, AZ", "Fresno, CA", "Sacramento, CA"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for a city...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            performSearch(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                            searchResults = []
                        }
                        .foregroundColor(.appColor)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.secondaryBgColor)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top)
                
                // Current Location Button
                Button {
                    requestCurrentLocation()
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.appColor)
                        Text("Use Current Location")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.labelColor)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.secondaryBgColor.opacity(0.5))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Search Results
                if isSearching {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding()
                        Text("Searching...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { city in
                        Button {
                            selectedLocation = city
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "mappin.circle")
                                    .foregroundColor(.appColor)
                                Text(city)
                                    .foregroundColor(.labelColor)
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                } else if !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No cities found")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        Text("Try searching for a different city name")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Popular Cities
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Popular Cities")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.labelColor)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(sampleCities.prefix(10), id: \.self) { city in
                                Button {
                                    selectedLocation = city
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: "mappin.circle")
                                            .foregroundColor(.appColor)
                                        Text(city)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.labelColor)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.secondaryBgColor)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .background(Color.bgColor.ignoresSafeArea())
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.appColor)
                }
            }
        }
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // Simulate search delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let filteredCities = sampleCities.filter { city in
                city.lowercased().contains(query.lowercased())
            }
            searchResults = filteredCities
            isSearching = false
        }
    }
    
    private func requestCurrentLocation() {
        // In a real app, you would implement Core Location here
        // For now, we'll simulate getting the current location
        let locationManager = CLLocationManager()
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Simulate getting current location
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                selectedLocation = "Current Location"
                dismiss()
            }
        case .denied, .restricted:
            // Show alert to enable location permissions
            selectedLocation = "Location Access Denied"
            dismiss()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

#Preview {
    LocationPickerView(selectedLocation: .constant("New York, NY"))
}

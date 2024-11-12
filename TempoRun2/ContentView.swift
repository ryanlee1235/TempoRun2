//
//  ContentView.swift
//  TempoRun2
//
//  Created by Ryan Lee on 11/9/24.
//


import SwiftUI

enum SearchFilterType: String, CaseIterable, Identifiable {
    case all = "All"
    case track = "Tracks"
    case artist = "Artists"

    var id: String { self.rawValue }
}

struct ContentView: View {
    @State private var query: String = ""
    @State private var suggestions: [SearchResult] = []
    @State private var showSuggestions = false
    @State private var selectedSearchFilter: SearchFilterType = .all
    @State private var selectedItems: Set<SearchResult> = []
    @StateObject private var storedList = StoredList()
    @State private var favoriteTrackIDs: [String] = []
    @State private var favoriteArtistIDs: [String] = []
    private let spotifyAPI = SpotifyAPI()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search bar for user input
                TextField("Search for a song or artist", text: $query, onEditingChanged: { isEditing in
                    if isEditing {
                        showSuggestions = true
                    }
                })
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: query) { _,newValue in
                    fetchSuggestions()
                }

                // Segmented control to filter search recommendations
                if !filteredSuggestions.isEmpty {
                    Picker("Search Filter", selection: $selectedSearchFilter) {
                        ForEach(SearchFilterType.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                }

                // Display filtered search suggestions
                if showSuggestions && !filteredSuggestions.isEmpty {
                    List(filteredSuggestions, id: \.id) { suggestion in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(suggestion.name)
                                    .font(.headline)
                                if let artistName = suggestion.artistName {
                                    Text(artistName)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Text(suggestion.type.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(suggestion.type == .track ? .blue : .green)
                                /*if suggestion.type == .track {
                                    var bpm = ""
                                    spotifyAPI.getSongBPM(trackID: track.id) { tempo in
                                        DispatchQueue.main.async {
                                            if let tempo = tempo {
                                                bpm = "\(Int(tempo)) BPM"
                                            } else {
                                                bpm = "Failed to get BPM"
                                            }
                                        }
                                        Text(bpm)
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }*/
                            }
                            Spacer()
                            // Selection button
                            Button(action: {
                                toggleSelection(for: suggestion)
                            }) {
                                Image(systemName: selectedItems.contains(suggestion) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedItems.contains(suggestion) ? .green : .gray)
                            }
                        }
                    }
                    .frame(height: 200)

                    // Button to add selected items to favorites
                    Button(action: {
                        addToFavorites()
                    }) {
                        Text("Add to Experience (\(selectedItems.count) selected)")
                            .padding()
                            .background(selectedItems.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(selectedItems.isEmpty)
                    }
                }

                // Display the list of favorite items
                List {
                    ForEach(storedList.favorites, id: \.id) { favorite in
                        VStack(alignment: .leading) {
                            Text(favorite.name)
                                .font(.headline)
                            if let artistName = favorite.artistName {
                                Text(artistName)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Text(favorite.type.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(favorite.type == .track ? .blue : .green)
                        }
                    }
                    .onDelete(perform: deleteFavorite)
                }
                .navigationTitle("Tailor Your Experience")
            }
            .padding()
            .onAppear {
                spotifyAPI.getAccessToken { success in
                    if !success {
                        print("Failed to get access token")
                    }
                }
            }
        }
    }

    // Toggle selection of an item
    private func toggleSelection(for item: SearchResult) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }

    // Filtered search suggestions based on the selected filter
    private var filteredSuggestions: [SearchResult] {
        switch selectedSearchFilter {
        case .all:
            if let firstArtist = suggestions.first(where: { $0.type == .artist }) {
                return [firstArtist] + suggestions.filter { $0.type == .track }
            } else {
                return suggestions.filter { $0.type == .track }
            }
        case .track:
            return suggestions.filter { $0.type == .track }
        case .artist:
            return suggestions.filter { $0.type == .artist }
        }
    }

    // Fetch search suggestions based on user input
    private func fetchSuggestions() {
        guard !query.isEmpty else {
            suggestions = []
            return
        }

        spotifyAPI.fetchSearchSuggestions(query: query) { results in
            DispatchQueue.main.async {
                self.suggestions = results
                self.selectedItems.removeAll() // Reset selection when new suggestions are fetched
            }
        }
    }

    // Method to update favorite track and artist IDs
    private func updateFavoriteIDs() {
        // Filter the favorites list for tracks and artists, then map their IDs
        favoriteTrackIDs = storedList.favorites
            .filter { $0.type == .track }
            .map { $0.id }

        favoriteArtistIDs = storedList.favorites
            .filter { $0.type == .artist }
            .map { $0.id }

        // Debug print statements
        print("Favorite Track IDs: \(favoriteTrackIDs)")
        print("Favorite Artist IDs: \(favoriteArtistIDs)")
    }

    // Add selected items to the favorites list
    private func addToFavorites() {
        for item in selectedItems {
            storedList.addToFavorites(item)
        }
        selectedItems.removeAll() // Clear selection after adding to favorites
        updateFavoriteIDs() // Update the favorite IDs
    }

    // Delete a favorite item from the list
    private func deleteFavorite(at offsets: IndexSet) {
        offsets.forEach { index in
            let item = storedList.favorites[index]
            storedList.removeFromFavorites(item)
        }
        updateFavoriteIDs() // Update the favorite IDs after deletion
    }
}

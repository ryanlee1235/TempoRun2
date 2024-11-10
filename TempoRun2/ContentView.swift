//
//  ContentView.swift
//  TempoRun2
//
//  Created by Ryan Lee on 11/9/24.
//

/*import SwiftUI

struct ContentView: View {
    @State private var query: String = ""
    @State private var bpm: String = "Enter a song title or artist"
    private let spotifyAPI = SpotifyAPI()

    var body: some View {
        VStack(spacing: 20) {
            TextField("Search for a song", text: $query)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                bpm = "Searching..."
                spotifyAPI.getAccessToken { success in
                    guard success else {
                        bpm = "Failed to get access token"
                        return
                    }

                    spotifyAPI.searchSong(query: query) { trackID in
                        guard let trackID = trackID else {
                            bpm = "Song not found"
                            return
                        }

                        spotifyAPI.getSongBPM(trackID: trackID) { tempo in
                            DispatchQueue.main.async {
                                bpm = tempo != nil ? "BPM: \(Int(tempo!))" : "Failed to get BPM"
                            }
                        }
                    }
                }
            }) {
                Text("Search")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Text(bpm)
                .padding()
                .font(.title)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
*/

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
                        Text("Add to List (\(selectedItems.count) selected)")
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
                .navigationTitle("Personalization")
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

    // Add selected items to the favorites list
    private func addToFavorites() {
        for item in selectedItems {
            storedList.addToFavorites(item)
        }
        selectedItems.removeAll() // Clear selection after adding to favorites
    }

    // Delete a favorite item from the list
    private func deleteFavorite(at offsets: IndexSet) {
        offsets.forEach { index in
            let item = storedList.favorites[index]
            storedList.removeFromFavorites(item)
        }
    }
}

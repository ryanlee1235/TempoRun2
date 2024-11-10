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

struct ContentView: View {
    @State private var query: String = ""
    @State private var suggestions: [SearchResult] = []
    @State private var showSuggestions = false
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

                // Display search suggestions
                if showSuggestions && !suggestions.isEmpty {
                    List(suggestions, id: \.id) { suggestion in
                        Button(action: {
                            query = suggestion.name
                            showSuggestions = false
                            addToFavorites(suggestion)
                        }) {
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
                        }
                    }
                    .frame(height: 400)
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
                .navigationTitle("Favorites")
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

    // Fetch search suggestions based on user input
    private func fetchSuggestions() {
        guard !query.isEmpty else {
            suggestions = []
            return
        }

        spotifyAPI.fetchSearchSuggestions(query: query) { results in
            DispatchQueue.main.async {
                self.suggestions = results
            }
        }
    }

    // Add a selected item to the favorites list
    private func addToFavorites(_ item: SearchResult) {
        storedList.addToFavorites(item)
    }

    // Delete a favorite item from the list
    private func deleteFavorite(at offsets: IndexSet) {
        offsets.forEach { index in
            let item = storedList.favorites[index]
            storedList.removeFromFavorites(item)
        }
    }
}

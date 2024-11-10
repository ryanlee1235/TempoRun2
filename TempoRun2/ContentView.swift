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
    @State private var bpm: String = "Enter a song title, artist, or genre"
    @State private var suggestions: [SearchResult] = []
    @State private var showSuggestions = false
    private let spotifyAPI = SpotifyAPI()

    var body: some View {
        VStack(spacing: 20) {
            TextField("Search for a song, artist, or genre", text: $query, onEditingChanged: { isEditing in
                if isEditing {
                    showSuggestions = true
                }
            })
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onChange(of: query) { _,newValue in
                fetchSuggestions()
            }

            if showSuggestions && !suggestions.isEmpty {
                List(suggestions, id: \.id) { suggestion in
                    Button(action: {
                        query = suggestion.name
                        showSuggestions = false
                        handleSelection(suggestion)
                    }) {
                        VStack(alignment: .leading) {
                            Text(suggestion.name)
                                .font(.headline)
                            if suggestion.type == .track {
                                Text(suggestion.artistName ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Text(suggestion.type.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .frame(height: 200)
            }

            Text(bpm)
                .padding()
                .font(.title)
        }
        .padding()
        .onAppear {
            spotifyAPI.getAccessToken { success in
                if !success {
                    bpm = "Failed to get access token"
                }
            }
        }
    }

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

    private func handleSelection(_ suggestion: SearchResult) {
        switch suggestion.type {
        case .track:
            fetchBPM(for: suggestion)
        case .artist:
            bpm = "Selected artist: \(suggestion.name)"
        case .genre:
            bpm = "Selected genre: \(suggestion.name)"
        }
    }

    private func fetchBPM(for track: SearchResult) {
        spotifyAPI.getSongBPM(trackID: track.id) { tempo in
            DispatchQueue.main.async {
                if let tempo = tempo {
                    bpm = "BPM: \(Int(tempo))"
                } else {
                    bpm = "Failed to get BPM"
                }
            }
        }
    }
}

//
//  Models.swift
//  TempoRun2
//
//  Created by Ryan Lee on 11/9/24.
//

import Foundation

/// Enum to categorize the type of search result (track, artist, genre)
enum ResultType: String, Codable {
    case track
    case artist
    case genre
}

/// Struct for search results, including tracks, artists, and genres
struct SearchResult: Identifiable, Codable {
    let id: String
    let name: String
    let type: ResultType
    let artistName: String?

    /// Initialize a search result with optional artist name
    init(id: String, name: String, type: ResultType, artistName: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.artistName = artistName
    }
}

/// Struct for the Spotify API search response
struct SearchResponse: Codable {
    let tracks: TracksResponse?
    let artists: ArtistsResponse?
}

/// Struct for track search results
struct TracksResponse: Codable {
    let items: [Track]
}

/// Struct for artist search results
struct ArtistsResponse: Codable {
    let items: [Artist]
}

/// Struct for a single track item
struct Track: Codable, Identifiable {
    let id: String
    let name: String
    let artists: [Artist]

    /// Helper method to get the first artist's name
    var firstArtistName: String? {
        return artists.first?.name
    }
}

/// Struct for a single artist item
struct Artist: Codable, Identifiable {
    let id: String
    let name: String
}

struct AudioFeatures: Codable {
    let tempo: Double
}

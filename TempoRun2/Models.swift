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
struct SearchResult: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let type: ResultType
    let artistName: String?

    // Implement the hash function explicitly (optional)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Implement equality explicitly (optional)
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.id == rhs.id
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

//
//  SpotifyAPI.swift
//  TempoRun2
//
//  Created by Ryan Lee on 11/9/24.
//

import Foundation

class SpotifyAPI {
    private let clientID = "9560ef7bbc08430faa2c2ae1b5209dd5"
    private let clientSecret = "c5bbdc77b4f24414975139b4a11acf93"
    private var accessToken: String?

    // Function to get Spotify API access token
    func getAccessToken(completion: @escaping (Bool) -> Void) {
        let tokenURL = "https://accounts.spotify.com/api/token"
        let credentials = "\(clientID):\(clientSecret)"
        guard let encodedCredentials = credentials.data(using: .utf8)?.base64EncodedString() else {
            completion(false)
            return
        }

        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let bodyData = "grant_type=client_credentials"
        request.httpBody = bodyData.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = json["access_token"] as? String {
                    self.accessToken = token
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                completion(false)
            }
        }.resume()
    }

    // Function to fetch search suggestions
    func fetchSearchSuggestions(query: String, completion: @escaping ([SearchResult]) -> Void) {
        guard let accessToken = accessToken else {
            completion([])
            return
        }

        let searchURL = "https://api.spotify.com/v1/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&type=track,artist&limit=5"
        var request = URLRequest(url: URL(string: searchURL)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }

            do {
                let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
                var results: [SearchResult] = []

                // Process artists
                if let artists = searchResponse.artists?.items {
                    //for artist in artists {
                        let result = SearchResult(id: artists[0].id, name: artists[0].name, type: .artist, artistName: nil)
                        results.append(result)
                    //}
                }
                
                // Process tracks
                if let tracks = searchResponse.tracks?.items {
                    for track in tracks {
                        let result = SearchResult(id: track.id, name: track.name, type: .track, artistName: track.artists.first?.name)
                        results.append(result)
                    }
                }

                completion(results)
            } catch {
                completion([])
            }
        }.resume()
    }
}

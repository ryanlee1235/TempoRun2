//
//  StoredList.swift
//  TempoRun2
//
//  Created by Ryan Lee on 11/10/24.
//

import Foundation

class StoredList: ObservableObject {
    @Published var favorites: [SearchResult] = []

    func addToFavorites(_ item: SearchResult) {
        if !favorites.contains(where: { $0.id == item.id }) {
            favorites.append(item)
        }
    }

    func removeFromFavorites(_ item: SearchResult) {
        favorites.removeAll { $0.id == item.id }
    }
}

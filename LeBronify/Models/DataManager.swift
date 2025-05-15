//
//  DataManager.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import Foundation

class DataManager {
    private let songsKey = "lebronify_songs"
    private let playlistsKey = "lebronify_playlists"
    
    // Singleton instance
    static let shared = DataManager()
    
    private init() {}
    
    // MARK: - Song Management
    
    func saveSongs(_ songs: [Song]) {
        print("DataManager: Saving \(songs.count) songs")
        do {
            let data = try JSONEncoder().encode(songs)
            UserDefaults.standard.set(data, forKey: songsKey)
        } catch {
            print("DataManager: Error saving songs: \(error)")
        }
    }
    
    func loadSongs() -> [Song] {
        print("DataManager: Loading songs")
        
        // Try to load existing songs from storage first
        if let savedSongsData = UserDefaults.standard.data(forKey: songsKey) {
            do {
                let songs = try JSONDecoder().decode([Song].self, from: savedSongsData)
                if !songs.isEmpty {
                    print("DataManager: Loaded \(songs.count) songs from storage")
                    return songs
                }
            } catch {
                print("DataManager: Error loading songs: \(error)")
            }
        }
        
        // If no songs in storage or there was an error, discover them fresh
        print("DataManager: No songs found in storage, discovering from bundle")
        let discoveredSongs = SongManager.shared.discoverSongsInBundle()
        
        if !discoveredSongs.isEmpty {
            saveSongs(discoveredSongs)
            
            // Also create default playlists for these songs
            createDefaultPlaylists(for: discoveredSongs)
        }
        
        return discoveredSongs
    }
    
    private func discoverAndSaveSongs() -> [Song] {
        print("DataManager: Performing fresh song discovery")
        
        // Use SongManager to discover songs in the bundle
        let discoveredSongs = SongManager.shared.discoverSongsInBundle()
        
        // Save the discovered songs
        if !discoveredSongs.isEmpty {
            saveSongs(discoveredSongs)
            print("DataManager: Discovered and saved \(discoveredSongs.count) songs")
            
            // Also ensure default playlists exist for these songs
            createDefaultPlaylists(for: discoveredSongs)
        } else {
            print("DataManager: Warning - No songs were discovered in the bundle")
        }
        
        return discoveredSongs
    }
    
    func updateSong(_ song: Song) {
        var songs = loadSongs()
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index] = song
            saveSongs(songs)
        }
    }
    
    // MARK: - Playlist Management
    
    func savePlaylists(_ playlists: [Playlist]) {
        do {
            let data = try JSONEncoder().encode(playlists)
            UserDefaults.standard.set(data, forKey: playlistsKey)
        } catch {
            print("Error saving playlists: \(error)")
        }
    }
    
    func loadPlaylists() -> [Playlist] {
        guard let data = UserDefaults.standard.data(forKey: playlistsKey) else {
            return createDefaultPlaylists(for: loadSongs())
        }
        
        do {
            let playlists = try JSONDecoder().decode([Playlist].self, from: data)
            return playlists.isEmpty ? createDefaultPlaylists(for: loadSongs()) : playlists
        } catch {
            print("Error loading playlists: \(error)")
            return createDefaultPlaylists(for: loadSongs())
        }
    }
    
    func updatePlaylist(_ playlist: Playlist) {
        var playlists = loadPlaylists()
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index] = playlist
            savePlaylists(playlists)
        } else {
            playlists.append(playlist)
            savePlaylists(playlists)
        }
    }
    
    // MARK: - Dynamic Playlist Creation
    
    @discardableResult
    private func createDefaultPlaylists(for songs: [Song]) -> [Playlist] {
        print("DataManager: Creating/updating default playlists")
        
        // First check if playlists already exist
        if let data = UserDefaults.standard.data(forKey: playlistsKey) {
            do {
                let existingPlaylists = try JSONDecoder().decode([Playlist].self, from: data)
                if !existingPlaylists.isEmpty {
                    print("DataManager: Found \(existingPlaylists.count) existing playlists")
                    return existingPlaylists
                }
            } catch {
                print("DataManager: Error loading playlists: \(error)")
            }
        }
        
        // Create default playlists if none exist
        print("DataManager: Creating new default playlists")
        var playlists: [Playlist] = []
        
        // System playlists - use consistent UUIDs
        let recentlyPlayedID = UUID(uuidString: "11111111-0000-0000-0000-000000000001")!
        let topHitsID = UUID(uuidString: "11111111-0000-0000-0000-000000000002")!
        let favoritesID = UUID(uuidString: "11111111-0000-0000-0000-000000000003")!
        
        playlists = [
            // System playlists
            Playlist(
                id: recentlyPlayedID,
                name: "Recently Played",
                description: "Your recently played LeBron tracks",
                coverImage: "lebron_recent",
                songIDs: [],
                isSystem: true
            ),
            Playlist(
                id: topHitsID,
                name: "Top Hits",
                description: "Most played LeBron parodies",
                coverImage: "lebron_top",
                songIDs: [],
                isSystem: true
            ),
            Playlist(
                id: favoritesID,
                name: "Favorites",
                description: "Your favorite LeBron songs",
                coverImage: "lebron_favorites",
                songIDs: [],
                isSystem: true
            )
        ]
        
        // Add category playlists based on song metadata
        var allCategories = Set<String>()
        
        // Collect all categories
        for song in songs {
            for category in song.categories {
                allCategories.insert(category)
            }
        }
        
        // Create a playlist for each category
        for category in allCategories {
            // Generate a consistent UUID for the category playlist
            let categoryData = category.data(using: .utf8)!
            var seed = Data(repeating: 0, count: 16)
            
            // Copy as many bytes as we have (up to 16)
            let bytesToCopy = min(categoryData.count, 16)
            categoryData.withUnsafeBytes { sourceBuffer in
                seed.withUnsafeMutableBytes { destBuffer in
                    if let sourcePtr = sourceBuffer.baseAddress, let destPtr = destBuffer.baseAddress {
                        memcpy(destPtr, sourcePtr, bytesToCopy)
                    }
                }
            }
            
            // Create a UUID from the hash bytes
            let categoryID = seed.withUnsafeBytes { bytes in
                return NSUUID(uuidBytes: bytes) as UUID
            }
            
            // Find songs in this category
            let categoryFilteredSongs = songs.filter { $0.categories.contains(category) }
            let songIDs = categoryFilteredSongs.map { $0.id }
            
            // Create the playlist
            if !songIDs.isEmpty {
                let playlist = Playlist(
                    id: categoryID,
                    name: category,
                    description: "LeBron songs in the \(category) category",
                    coverImage: getCoverImageForCategory(category),
                    songIDs: songIDs,
                    isSystem: false
                )
                playlists.append(playlist)
            }
        }
        
        // Save all playlists
        savePlaylists(playlists)
        print("DataManager: Created \(playlists.count) playlists")
        return playlists
    }
    
    private func getCoverImageForCategory(_ category: String) -> String {
        // Map categories to appropriate cover images
        switch category.lowercased() {
            case "lakers":
                return "lebron_lakers"
            case "king james":
                return "lebron_crown"
            case "love songs":
                return "lebron_love"
            case "basketball":
                return "lebron_ball"
            case "lebron memes":
                return "lebron_meme"
            case "ilyaugust":
                return "ilyaugust"
            default:
                return "lebron_default"
        }
    }
    
    // MARK: - Dynamic Playlist Management
    
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: songsKey)
        UserDefaults.standard.removeObject(forKey: playlistsKey)
        print("DataManager: Cleared all data")
    }
    
    private func getSongsFromStorage() -> [Song] {
        if let savedSongsData = UserDefaults.standard.data(forKey: songsKey) {
            do {
                return try JSONDecoder().decode([Song].self, from: savedSongsData)
            } catch {
                print("DataManager: Error directly loading songs: \(error)")
            }
        }
        return []
    }

    func getRecentlyPlayedSongs(limit: Int = 10) -> [Song] {
        let songs = getSongsFromStorage()
        let recentSongs = songs
            .filter { $0.lastPlayed != nil }
            .sorted { ($0.lastPlayed ?? Date.distantPast) > ($1.lastPlayed ?? Date.distantPast) }
            .prefix(limit)
            .map { $0 }
        
        print("DataManager: Found \(recentSongs.count) recently played songs")
        return recentSongs
    }

    func getTopHitsSongs(limit: Int = 10) -> [Song] {
        let songs = getSongsFromStorage()
        let topSongs = songs
            .sorted { $0.playCount > $1.playCount }
            .prefix(limit)
            .map { $0 }
        
        print("DataManager: Found \(topSongs.count) top hit songs")
        return topSongs
    }

    func getFavoriteSongs() -> [Song] {
        let songs = getSongsFromStorage()
        let favSongs = songs.filter { $0.isFavorite }
        print("DataManager: Found \(favSongs.count) favorite songs")
        return favSongs
    }

    func getSongsForPlaylist(_ playlist: Playlist) -> [Song] {
        if playlist.isSystem {
            switch playlist.name {
            case "Recently Played":
                return getRecentlyPlayedSongs()
            case "Top Hits":
                return getTopHitsSongs()
            case "Favorites":
                return getFavoriteSongs()
            default:
                break
            }
        }
        
        let allSongs = getSongsFromStorage()
        let playlistSongs = allSongs.filter { playlist.songIDs.contains($0.id) }
        print("DataManager: Found \(playlistSongs.count) songs for playlist: \(playlist.name)")
        return playlistSongs
    }
    
    func loadSongsDirectlyFromStorage() -> [Song] {
        if let savedSongsData = UserDefaults.standard.data(forKey: songsKey) {
            do {
                let songs = try JSONDecoder().decode([Song].self, from: savedSongsData)
                print("DataManager: Directly loaded \(songs.count) songs from storage")
                return songs
            } catch {
                print("DataManager: Error directly loading songs from storage: \(error)")
            }
        }
        print("DataManager: No songs found in direct storage load")
        return []
    }
    
    func updatePlayCount(for songID: UUID) {
        print("DataManager: Starting updatePlayCount for song ID: \(songID)")
        // Load songs directly from storage
        var songs = loadSongsDirectlyFromStorage()
        
        // Find and update the specific song
        if let index = songs.firstIndex(where: { $0.id == songID }) {
            songs[index].playCount += 1
            songs[index].lastPlayed = Date()
            print("DataManager: Increased play count for song: \(songs[index].title) to \(songs[index].playCount)")
            saveSongs(songs)
            
            // Add this debug log to verify the song was saved
            print("DataManager: Successfully saved updated play count")
        } else {
            print("DataManager: WARNING - Could not find song to update play count for ID: \(songID)")
        }
    }

    func toggleFavorite(for songID: UUID) {
        print("DataManager: Toggling favorite status for song ID: \(songID)")
        
        var songs = getSongsFromStorage()
        if let index = songs.firstIndex(where: { $0.id == songID }) {
            songs[index].isFavorite.toggle()
            let newStatus = songs[index].isFavorite ? "favorite" : "not favorite"
            print("DataManager: Song \(songs[index].title) is now \(newStatus)")
            saveSongs(songs)
        } else {
            print("DataManager: Warning - Could not find song to toggle favorite for ID: \(songID)")
        }
    }
    
    // MARK: - Updated Methods for Refreshing
    
    func forceRefreshAllSongs() {
        print("DataManager: Forcing a one-time complete song refresh")
        
        // Get existing songs to preserve metadata (play counts, favorites)
        var existingSongs: [Song] = []
        var existingSongMap: [UUID: Song] = [:]
        
        if let savedSongsData = UserDefaults.standard.data(forKey: songsKey) {
            do {
                existingSongs = try JSONDecoder().decode([Song].self, from: savedSongsData)
                
                // Create a lookup map of existing songs by ID
                for song in existingSongs {
                    existingSongMap[song.id] = song
                }
            } catch {
                print("DataManager: Error loading existing songs: \(error)")
            }
        }
        
        // Now discover fresh songs from the bundle
        let discoveredSongs = SongManager.shared.discoverSongsInBundle()
        print("DataManager: Discovered \(discoveredSongs.count) songs from bundle")
        
        // Merge the discovered songs with existing data to preserve play counts
        var mergedSongs: [Song] = []
        
        for discoveredSong in discoveredSongs {
            if let existingSong = existingSongMap[discoveredSong.id] {
                // Found existing song - keep its play count, favorites status, etc.
                var updatedSong = discoveredSong
                updatedSong.playCount = existingSong.playCount
                updatedSong.lastPlayed = existingSong.lastPlayed
                updatedSong.isFavorite = existingSong.isFavorite
                mergedSongs.append(updatedSong)
                print("DataManager: Merged existing song: \(updatedSong.title)")
            } else {
                // New song - add it as is
                mergedSongs.append(discoveredSong)
                print("DataManager: Added new song: \(discoveredSong.title)")
            }
        }
        
        // Save the merged songs
        saveSongs(mergedSongs)
        print("DataManager: Saved \(mergedSongs.count) merged songs")
        
        // Update playlist references
        updatePlaylistReferences(with: mergedSongs)
        
        print("DataManager: Force refresh complete")
    }
    
    // Updated function to force refresh all song data
    func refreshAllData() {
        print("DataManager: Performing complete data refresh")
        
        // Clear existing data
        UserDefaults.standard.removeObject(forKey: songsKey)
        
        // Rediscover all songs
        let songs = discoverAndSaveSongs()
        
        // Update playlist references
        updatePlaylistReferences(with: songs)
        
        print("DataManager: Data refresh complete")
    }
    
    // Update playlist references to make sure they point to valid songs
    private func updatePlaylistReferences(with songs: [Song]) {
        var playlists = loadPlaylists()
        let validSongIDs = Set(songs.map { $0.id })
        
        // Update each playlist to only include valid song IDs
        for i in 0..<playlists.count {
            let validPlaylistSongs = playlists[i].songIDs.filter { validSongIDs.contains($0) }
            playlists[i].songIDs = validPlaylistSongs
        }
        
        savePlaylists(playlists)
        print("DataManager: Updated \(playlists.count) playlists with valid song references")
    }
}

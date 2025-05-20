//
//  SongManager.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import Foundation
import AVFoundation

class SongManager {
    static let shared = SongManager()
    
    private init() {}
    
    // MARK: - Song Discovery
    
    func discoverSongsInBundle() -> [Song] {
        print("=== SCANNING FOR AUDIO FILES ===")
        var discoveredSongs: [Song] = []
        let fileManager = FileManager.default
        
        // Approach 1: Check for Songs directory first
        if let songsURL = Bundle.main.url(forResource: "Songs", withExtension: nil) {
            print("Found Songs directory in bundle")
            do {
                // Get all file URLs in the Songs directory
                let fileURLs = try fileManager.contentsOfDirectory(
                    at: songsURL,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
                )
                
                // Filter for audio files
                let audioFileURLs = fileURLs.filter { url in
                    let fileExtension = url.pathExtension.lowercased()
                    return ["mp3", "m4a", "wav", "aac"].contains(fileExtension)
                }
                
                print("Found \(audioFileURLs.count) audio files in Songs directory")
                discoveredSongs.append(contentsOf: processSongURLs(audioFileURLs, inSubDirectory: "Songs"))
            } catch {
                print("Error discovering songs in Songs directory: \(error)")
            }
        } else {
            print("No Songs directory found in bundle")
        }
        
        // Approach 2: Also check the main bundle for more audio files
        guard let resourceURL = Bundle.main.resourceURL else {
            print("Could not access app bundle resources")
            return discoveredSongs
        }
        
        do {
            // Get all file URLs in the main bundle
            let fileURLs = try fileManager.contentsOfDirectory(
                at: resourceURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            // Filter for audio files
            let audioFileURLs = fileURLs.filter { url in
                let fileExtension = url.pathExtension.lowercased()
                return ["mp3", "m4a", "wav", "aac"].contains(fileExtension)
            }
            
            print("Found \(audioFileURLs.count) audio files in main bundle")
            let mainBundleSongs = processSongURLs(audioFileURLs, inSubDirectory: nil)
            discoveredSongs.append(contentsOf: mainBundleSongs)
            
        } catch {
            print("Error discovering songs in main bundle: \(error)")
        }
        
        print("SongManager found a total of \(discoveredSongs.count) songs")
        
        // Log all discovered filenames for debugging
        for song in discoveredSongs {
            print("- \(song.title) (\(song.audioFileName))")
        }
        
        print("=== END OF AUDIO FILE SCAN ===")
        return discoveredSongs
    }
    
    // Helper method to process song URLs
    private func processSongURLs(_ urls: [URL], inSubDirectory: String?) -> [Song] {
        var songs: [Song] = []
        
        for url in urls {
            // Get basic file info
            let filename = url.lastPathComponent
            
            // Generate a consistent UUID based on the filename
            let songId = generateConsistentUUID(from: filename)
            
            // Get full path for audio file reference (including subdirectory if needed)
            let audioFilePath = inSubDirectory != nil ? "\(inSubDirectory!)/\(filename)" : filename
            
            // Get audio duration - using AVURLAsset instead of deprecated AVAsset(url:)
            var duration: TimeInterval = 0
            let asset = AVURLAsset(url: url)
            
            // Use async/await to get duration instead of deprecated duration property
            Task {
                do {
                    let durationValue = try await asset.load(.duration)
                    duration = CMTimeGetSeconds(durationValue)
                    
                    // Update the song with the correct duration once loaded
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SongDurationUpdated"),
                        object: nil,
                        userInfo: ["songID": songId, "duration": duration]
                    )
                } catch {
                    print("Error loading duration for \(filename): \(error)")
                }
            }
            
            // Use estimated duration as initial value - will be updated when actual duration is loaded
            duration = TimeInterval.random(in: 120...240) // 2-4 minutes as fallback
            print("Using initial duration estimate for \(filename): \(duration)s")
            
            // Create a Song object
            let song = Song(
                id: songId,
                title: generateTitle(from: filename),
                artist: extractArtist(from: filename),
                albumArt: cleanNameForAsset(filename),
                audioFileName: audioFilePath,
                duration: duration,
                playCount: 0,
                lastPlayed: nil,
                isFavorite: false,
                categories: generateCategories(from: filename)
            )
            
            songs.append(song)
            print("Discovered song: \(song.title) by \(song.artist)")
        }
        
        return songs
    }
    
    // Generate a consistent UUID from a string
    private func generateConsistentUUID(from string: String) -> UUID {
        // Create a deterministic 16-byte hash from the string
        let data = string.data(using: .utf8)!
        var seed = Data(repeating: 0, count: 16)
        
        // Copy as many bytes as we have (up to 16)
        let bytesToCopy = min(data.count, 16)
        
        // Modern implementation with newer API
        data.withUnsafeBytes { sourceBuffer in
            seed.withUnsafeMutableBytes { destBuffer in
                let sourcePtr = sourceBuffer.baseAddress!
                let destPtr = destBuffer.baseAddress!
                memcpy(destPtr, sourcePtr, bytesToCopy)
            }
        }
        
        // Create a UUID from the hash bytes using modern API
        return seed.withUnsafeBytes { bytes in
            bytes.baseAddress!.assumingMemoryBound(to: UInt8.self).withMemoryRebound(to: uuid_t.self, capacity: 1) { pointer in
                return UUID(uuid: pointer.pointee)
            }
        }
    }
    
    // MARK: - Metadata Generation
    
    func generateTitle(from filename: String) -> String {
        // Remove artist info if present (after the dash)
        let parts = filename.components(separatedBy: " - ")
        let titlePart = parts[0]
        
        // Clean up and capitalize
        return titlePart
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
    
    func extractArtist(from filename: String) -> String {
        // Check for artist after dash
        let parts = filename.components(separatedBy: " - ")
        if parts.count > 1 {
            return parts[1]
                .replacingOccurrences(of: ".mp3", with: "")
                .replacingOccurrences(of: ".m4a", with: "")
                .replacingOccurrences(of: ".wav", with: "")
                .trimmingCharacters(in: .whitespaces)
        }
        
        // Default artist
        return "LeBron Fan"
    }
    
    func generateCategories(from filename: String) -> [String] {
        var categories: [String] = []
        let lowercaseName = filename.lowercased()
        
        // Add default category
        categories.append("LeBron Hits")
        
        // Categorize by content
        if lowercaseName.contains("marry") || lowercaseName.contains("romantic") ||
           lowercaseName.contains("sweet") || lowercaseName.contains("love") {
            categories.append("Love Songs")
        }
        
        if lowercaseName.contains("lakers") || lowercaseName.contains("la bron") {
            categories.append("Lakers")
        }
        
        if lowercaseName.contains("king") || lowercaseName.contains("crown") ||
           lowercaseName.contains("royal") {
            categories.append("King James")
        }
        
        // Categorize by artist
        if lowercaseName.contains("ilyaugust") {
            categories.append("ilyaugust")
        }
        
        // Categorize by style
        if lowercaseName.contains("dance") || lowercaseName.contains("party") {
            categories.append("Dance")
        }
        
        return categories
    }
    
    // MARK: - Helper Functions
    
    func cleanNameForAsset(_ name: String) -> String {
        // Clean the name to be used as an asset name
        // This will convert "Song Name - Artist.mp3" to "song_name"
        var cleanName = name
            .replacingOccurrences(of: ".mp3", with: "")
            .replacingOccurrences(of: ".m4a", with: "")
            .replacingOccurrences(of: ".wav", with: "")
        
        // Remove artist if present
        if cleanName.contains(" - ") {
            cleanName = cleanName.components(separatedBy: " - ")[0]
        }
        
        // Replace spaces with underscores and make lowercase
        cleanName = cleanName
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()
        
        return cleanName
    }
}

//
//  AlbumArtHelper.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//


import SwiftUI

// Helper class for album art management
class AlbumArtHelper {
    // Check if album art exists for a given song
    static func hasAlbumArt(for song: Song) -> Bool {
        return UIImage(named: song.albumArt) != nil
    }
    
    // Get album art for a song, falling back to a default if not found
    static func getAlbumArt(for song: Song) -> Image {
        // First try the exact album art name
        if let _ = UIImage(named: song.albumArt) {
            return Image(song.albumArt)
        }
        
        // Try variations of the song title
        let variations = [
            song.albumArt,
            song.title.replacingOccurrences(of: " ", with: "_").lowercased(),
            song.audioFileName.replacingOccurrences(of: " ", with: "_").lowercased(),
            song.audioFileName.replacingOccurrences(of: ".mp3", with: "").lowercased()
        ]
        
        for variation in variations {
            if let _ = UIImage(named: variation) {
                return Image(variation)
            }
        }
        
        // Fall back to default album art
        return getDefaultAlbumArt(for: song)
    }
    
    // Generate a default album art based on categories
    static func getDefaultAlbumArt(for song: Song) -> Image {
        // Try category-based defaults
        for category in song.categories {
            switch category.lowercased() {
            case "lakers":
                return Image("lebron_lakers")
            case "king james":
                return Image("lebron_crown")
            case "love songs":
                return Image("lebron_love")
            case "basketball":
                return Image("lebron_ball")
            case "lebron memes":
                return Image("lebron_meme")
            case "ilyaugust":
                if let _ = UIImage(named: "ilyaugust") {
                    return Image("ilyaugust")
                }
            default:
                break
            }
        }
        
        // Last resort: check if artist has a default image
        if song.artist != "LeBron Fan" {
            let artistImage = song.artist.replacingOccurrences(of: " ", with: "_").lowercased()
            if let _ = UIImage(named: artistImage) {
                return Image(artistImage)
            }
        }
        
        // Absolute fallback
        return Image("lebron_default")
    }
}

// Extension to make it easy to use in SwiftUI views
extension Image {
    static func albumArt(for song: Song) -> Image {
        return AlbumArtHelper.getAlbumArt(for: song)
    }
}

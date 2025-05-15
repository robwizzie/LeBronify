//
//  Song.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import Foundation

// Song model with additional metadata
struct Song: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let artist: String
    let albumArt: String
    let audioFileName: String
    let duration: TimeInterval
    var playCount: Int
    var lastPlayed: Date?
    var isFavorite: Bool
    var categories: [String]
    
    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        albumArt: String,
        audioFileName: String,
        duration: TimeInterval,
        playCount: Int = 0,
        lastPlayed: Date? = nil,
        isFavorite: Bool = false,
        categories: [String] = []
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumArt = albumArt
        self.audioFileName = audioFileName
        self.duration = duration
        self.playCount = playCount
        self.lastPlayed = lastPlayed
        self.isFavorite = isFavorite
        self.categories = categories
    }
}

// Playlist/category system
struct Playlist: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var coverImage: String
    var songIDs: [UUID]
    var isSystem: Bool // True for auto-generated playlists like "Recently Played"
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        coverImage: String,
        songIDs: [UUID] = [],
        isSystem: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.coverImage = coverImage
        self.songIDs = songIDs
        self.isSystem = isSystem
    }
}

// AD model for our Anthony Davis advertisements
struct AnthonyDavisAd: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let message: String
    
    static func randomAd() -> AnthonyDavisAd {
        let ads = [
            AnthonyDavisAd(
                title: "THE BROW KNOWS",
                imageName: "ad_pose1",
                message: "Need more hang time? Try AD's secret workout routine!"
            ),
            AnthonyDavisAd(
                title: "TRADE OFFER",
                imageName: "ad_pose2",
                message: "I receive: A trip to Dallas. You receive: This ad to disappear."
            ),
            AnthonyDavisAd(
                title: "AD BREAK",
                imageName: "ad_pose3",
                message: "While LeBron carries the team, I'm carrying these amazing deals!"
            ),
            AnthonyDavisAd(
                title: "TIMEOUT",
                imageName: "ad_pose4",
                message: "Even the King needs a break. AD here to remind you to stay hydrated!"
            )
        ]
        
        return ads.randomElement()!
    }
}

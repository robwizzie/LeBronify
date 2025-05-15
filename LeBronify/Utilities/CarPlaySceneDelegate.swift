//
//  CarPlaySceneDelegate.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/27/25.
//

import Foundation
import CarPlay
import MediaPlayer
import UIKit

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    
    // Use the shared viewModel from LeBronifyApp
    var viewModel: LeBronifyViewModel {
        return LeBronifyApp.viewModel
    }
    
    // MARK: - CPTemplateApplicationSceneDelegate
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        // Set up initial root template
        let rootTemplate = createRootTemplate()
        interfaceController.setRootTemplate(rootTemplate, animated: true)
        
        // Set up the audio session
        setupAudioSession()
        
        // Start observing for song changes to update the UI
        startObservingSongChanges()
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Template Creation
    
    private func createRootTemplate() -> CPTemplate {
        // Create tab bar with multiple tabs
        let tabBarTemplate = CPTabBarTemplate(templates: [
            createLibraryTemplate(),
            createPlaylistsTemplate(),
            createNowPlayingTemplate()
        ])
        
        return tabBarTemplate
    }
    
    private func createLibraryTemplate() -> CPTemplate {
        // Create library sections
        let sections = [
            createRecentlyPlayedSection(),
            createTopHitsSection(),
            createAllSongsSection()
        ]
        
        // Create action for random song
        let randomAction = CPGridButton(titleVariants: ["Random LeBron Song"],
                                      image: UIImage(systemName: "shuffle") ?? UIImage()) { [weak self] _ in
            if let randomSong = self?.viewModel.allSongs.randomElement() {
                self?.viewModel.playSong(randomSong)
                // Navigate to now playing screen
                if let tabTemplate = self?.interfaceController?.rootTemplate as? CPTabBarTemplate,
                   let nowPlayingTemplate = tabTemplate.templates.last {
                    self?.interfaceController?.pushTemplate(nowPlayingTemplate, animated: true)
                }
            }
        }
        
        // Create grid with random button
        let actionsGrid = CPGridTemplate(title: "LeBronify", gridButtons: [randomAction])
        
        // Create list template with sections
        let listTemplate = CPListTemplate(title: "Library", sections: sections)
        
        // Create template with both grid and list
        return CPTabBarTemplate(templates: [actionsGrid, listTemplate])
    }
    
    private func createPlaylistsTemplate() -> CPTemplate {
        // Get all playlists
        let playlists = viewModel.playlists
        
        // Create a section for each playlist type
        var sections: [CPListSection] = []
        
        // System playlists section (Recently Played, Top Hits, etc.)
        let systemPlaylists = playlists.filter { $0.isSystem }
        if !systemPlaylists.isEmpty {
            let playlistItems = systemPlaylists.map { createPlaylistItem($0) }
            sections.append(CPListSection(items: playlistItems, header: "System Playlists", sectionIndexTitle: "S"))
        }
        
        // User playlists section
        let userPlaylists = playlists.filter { !$0.isSystem }
        if !userPlaylists.isEmpty {
            let playlistItems = userPlaylists.map { createPlaylistItem($0) }
            sections.append(CPListSection(items: playlistItems, header: "Your Playlists", sectionIndexTitle: "Y"))
        }
        
        // If no playlists, add an empty state message
        if sections.isEmpty {
            let emptyItem = CPListItem(text: "No Playlists", detailText: "Create playlists in the main app")
            sections.append(CPListSection(items: [emptyItem], header: "Playlists", sectionIndexTitle: "P"))
        }
        
        return CPListTemplate(title: "Playlists", sections: sections)
    }
    
    private func createNowPlayingTemplate() -> CPTemplate {
        // CarPlay provides a shared now playing template that we should use
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        return nowPlayingTemplate
    }
    
    // MARK: - Section Creation
    
    private func createRecentlyPlayedSection() -> CPListSection {
        let recentSongs = viewModel.recentlyPlayedSongs
        
        if recentSongs.isEmpty {
            let emptyItem = CPListItem(text: "No Recently Played Songs", detailText: "")
            return CPListSection(items: [emptyItem], header: "Recently Played", sectionIndexTitle: "R")
        }
        
        let recentItems = recentSongs.map { createSongListItem($0) }
        return CPListSection(items: recentItems, header: "Recently Played", sectionIndexTitle: "R")
    }
    
    private func createTopHitsSection() -> CPListSection {
        let topSongs = viewModel.topHitsSongs
        
        if topSongs.isEmpty {
            let emptyItem = CPListItem(text: "No Top Hits Yet", detailText: "Play songs to see your top hits")
            return CPListSection(items: [emptyItem], header: "Top Hits", sectionIndexTitle: "T")
        }
        
        let topItems = topSongs.map { createSongListItem($0) }
        return CPListSection(items: topItems, header: "Top Hits", sectionIndexTitle: "T")
    }
    
    private func createAllSongsSection() -> CPListSection {
        let songs = viewModel.allSongs
        let songItems = songs.map { createSongListItem($0) }
        return CPListSection(items: songItems, header: "All Songs", sectionIndexTitle: "A")
    }
    
    // MARK: - Item Creation
    
    private func createSongListItem(_ song: Song) -> CPListItem {
        // Create an image for the song
        let image = UIImage(named: song.albumArt) ?? UIImage(systemName: "music.note") ?? UIImage()
        
        // Create a list item with the song details
        let item = CPListItem(text: song.title, detailText: song.artist, image: image)
        
        // Add a handler to play the song when selected
        item.handler = { [weak self] (listItem: CPSelectableListItem, completion: @escaping () -> Void) in
            self?.viewModel.playSong(song)
            
            // Navigate to now playing template
            if let tabTemplate = self?.interfaceController?.rootTemplate as? CPTabBarTemplate,
               let nowPlayingTemplate = tabTemplate.templates.last {
                self?.interfaceController?.pushTemplate(nowPlayingTemplate, animated: true)
            }
            
            completion()
        }
        
        return item
    }
    
    private func createPlaylistItem(_ playlist: Playlist) -> CPListItem {
        // Create an image for the playlist
        let image = UIImage(named: playlist.coverImage) ?? UIImage(systemName: "music.note.list") ?? UIImage()
        
        // Create a list item with the playlist details
        let item = CPListItem(text: playlist.name,
                             detailText: playlist.description,
                             image: image)
        
        // Add a handler to show the playlist when selected
        item.handler = { [weak self] (listItem: CPSelectableListItem, completion: @escaping () -> Void) in
            self?.showPlaylist(playlist)
            completion()
        }
        
        return item
    }
    
    // MARK: - Navigation
    
    private func showPlaylist(_ playlist: Playlist) {
        // Get songs in the playlist
        let playlistSongs = viewModel.getSongs(for: playlist)
        
        // Create list items for each song
        let songItems = playlistSongs.map { createSongListItem($0) }
        
        // Create a template for the playlist
        let section = CPListSection(items: songItems, header: playlist.name, sectionIndexTitle: "P")
        let playlistTemplate = CPListTemplate(title: playlist.name, sections: [section])
        
        // Push the template
        interfaceController?.pushTemplate(playlistTemplate, animated: true)
    }
    
    // MARK: - Observers
    
    private func startObservingSongChanges() {
        // Observe changes to current song to update now playing info
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateNowPlayingInfo),
            name: NSNotification.Name("SongChanged"),
            object: nil
        )
        
        // Initially update now playing info if a song is already playing
        if viewModel.currentSong != nil {
            updateNowPlayingInfo()
        }
    }
    
    // MARK: - Media Player Integration
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session in CarPlay: \(error)")
        }
    }
    
    @objc private func updateNowPlayingInfo() {
        guard let song = viewModel.currentSong else { return }
        
        var nowPlayingInfo = [String: Any]()
        
        // Set metadata
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = song.artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = song.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = viewModel.currentPlaybackTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = viewModel.isPlaying ? 1.0 : 0.0
        
        // Set album artwork
        if let image = UIImage(named: song.albumArt) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        // Update now playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

// MARK: - CPSearchTemplateDelegate
extension CarPlaySceneDelegate: CPSearchTemplateDelegate {
    func searchTemplate(_ searchTemplate: CPSearchTemplate,
                       updatedSearchText searchText: String,
                       completionHandler: @escaping ([CPListItem]) -> Void) {
        // Filter songs based on search text
        let filteredSongs = viewModel.allSongs.filter { song in
            return song.title.localizedCaseInsensitiveContains(searchText) ||
                   song.artist.localizedCaseInsensitiveContains(searchText)
        }
        
        // Create list items for the search results
        let items = filteredSongs.map { createSongListItem($0) }
        
        completionHandler(items)
    }
    
    func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {
        // Required implementation - can be empty if not needed
    }
    
    func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {
        // Required implementation
        completionHandler()
    }
}

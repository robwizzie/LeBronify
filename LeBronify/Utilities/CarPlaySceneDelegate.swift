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
        
        // Use the modern API for presenting templates
        if #available(iOS 14.0, *) {
            interfaceController.setRootTemplate(rootTemplate, animated: true, completion: nil)
        } else {
            // Fallback for older iOS versions
            interfaceController.presentTemplate(rootTemplate, animated: true)
        }
        
        // Don't set up the audio session here
        // It will be initialized on-demand when needed by AudioPlaybackManager
        
        // Start observing for song changes to update the UI
        startObservingSongChanges()
    }
    
    // MARK: - Template Creation
    
    private func createRootTemplate() -> CPTemplate {
        // Create each tab template
        let libraryTemplate = createLibraryTemplate()
        let playlistsTemplate = createPlaylistsTemplate()
        let nowPlayingTemplate = createNowPlayingTemplate()
        let searchTemplate = createSearchTemplate()
        
        // Create tab bar with multiple tabs
        let tabBarTemplate = CPTabBarTemplate(templates: [
            libraryTemplate,
            playlistsTemplate,
            searchTemplate,
            nowPlayingTemplate
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
                
                // Navigate to now playing screen - CPNowPlayingTemplate.shared is not optional
                let nowPlayingTemplate = CPNowPlayingTemplate.shared
                // Use the modern API for pushing templates
                if #available(iOS 14.0, *) {
                    self?.interfaceController?.pushTemplate(nowPlayingTemplate, animated: true, completion: nil)
                } else {
                    // Fallback for older iOS versions
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
    
    private func createSearchTemplate() -> CPTemplate {
        // Create search template
        let searchTemplate = CPSearchTemplate()
        searchTemplate.delegate = self
        
        return searchTemplate
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
            
            // Navigate to now playing template - CPNowPlayingTemplate.shared is not optional
            let nowPlayingTemplate = CPNowPlayingTemplate.shared
            
            // Use the modern API for pushing templates
            if #available(iOS 14.0, *) {
                self?.interfaceController?.pushTemplate(nowPlayingTemplate, animated: true, completion: nil)
            } else {
                // Fallback for older iOS versions
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
        if #available(iOS 14.0, *) {
            interfaceController?.pushTemplate(playlistTemplate, animated: true, completion: nil)
        } else {
            // Fallback for older iOS versions
            interfaceController?.pushTemplate(playlistTemplate, animated: true)
        }
    }
    
    // MARK: - Media Player Integration
    
    // Modified to be called on-demand and not during CarPlay connection
    private func setupAudioSession() {
        // The audio session is now handled by AudioPlaybackManager
        // This method is kept for compatibility but won't be called directly
        print("CarPlaySceneDelegate: Audio session setup is handled by AudioPlaybackManager")
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
        
        // Add observers for playback status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackStarted),
            name: NSNotification.Name("PlaybackStarted"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackPaused),
            name: NSNotification.Name("PlaybackPaused"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlaybackStopped),
            name: NSNotification.Name("PlaybackStopped"),
            object: nil
        )
        
        // Initially update now playing info if a song is already playing
        if viewModel.currentSong != nil {
            updateNowPlayingInfo()
        }
    }
    
    @objc private func updateNowPlayingInfo(_ notification: Notification? = nil) {
        // If notification provided, extract song info from it
        if let notification = notification,
           let userInfo = notification.userInfo,
           let song = userInfo["song"] as? Song {
            
            // Update CarPlay Now Playing template
            updateCarPlayNowPlaying(
                song: song,
                isPlaying: userInfo["isPlaying"] as? Bool ?? false,
                currentTime: userInfo["currentTime"] as? TimeInterval ?? 0,
                duration: userInfo["duration"] as? TimeInterval ?? 0
            )
            return
        }
            
        // Fallback to ViewModel if notification not provided
        guard let song = viewModel.currentSong else { return }
        
        updateCarPlayNowPlaying(
            song: song,
            isPlaying: viewModel.isPlaying,
            currentTime: viewModel.currentPlaybackTime,
            duration: song.duration
        )
    }
    
    private func updateCarPlayNowPlaying(song: Song, isPlaying: Bool, currentTime: TimeInterval, duration: TimeInterval) {
        // CarPlay's template will automatically use the MPNowPlayingInfoCenter data
        // We don't need to manually configure buttons as CarPlay handles this
        
        // Just make sure the system's now playing info is up-to-date
        var nowPlayingInfo = [String: Any]()
        
        // Set metadata
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = song.artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // Set album artwork
        if let image = UIImage(named: song.albumArt) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        // Update now playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    @objc private func handlePlaybackStarted() {
        updateNowPlayingInfo()
    }
    
    @objc private func handlePlaybackPaused() {
        updateNowPlayingInfo()
    }
    
    @objc private func handlePlaybackStopped() {
        // Clear the now playing template or update with stopped state
        updateNowPlayingInfo()
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

// MARK: - CPTemplateApplicationSceneDelegate Additional Methods
extension CarPlaySceneDelegate {
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnect interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        NotificationCenter.default.removeObserver(self)
    }
}

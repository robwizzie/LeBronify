//
//  QueueView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 5/14/25.
//


//
//  QueueView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 5/14/25.
//

import SwiftUI

struct QueueView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var editMode = EditMode.inactive
    
    var body: some View {
        NavigationView {
            VStack {
                // Current song display
                if let currentSong = viewModel.queueManager.currentSongInQueue {
                    HStack(spacing: 16) {
                        Image.albumArt(for: currentSong)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading) {
                            Text("Now Playing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(currentSong.title)
                                .font(.headline)
                            
                            Text(currentSong.artist)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Queue list
                List {
                    Section(header: Text("UP NEXT")) {
                        ForEach(Array(viewModel.queueManager.currentQueue.enumerated()), id: \.element.id) { index, song in
                            if index != viewModel.queueManager.queueIndex {
                                HStack(spacing: 12) {
                                    Image.albumArt(for: song)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(6)
                                    
                                    VStack(alignment: .leading) {
                                        Text(song.title)
                                            .font(.body)
                                        
                                        Text(song.artist)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    // Larger play button with better touch target
                                    Button(action: {
                                        viewModel.queueManager.jumpToSong(at: index)
                                        viewModel.playSong(song)
                                    }) {
                                        Image(systemName: "play.circle")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                    
                                    // Larger remove button with better touch target
                                    Button(action: {
                                        viewModel.queueManager.removeFromQueue(at: index)
                                    }) {
                                        Image(systemName: "minus.circle")
                                            .font(.title2)
                                            .foregroundColor(.red)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onMove { source, destination in
                            viewModel.queueManager.moveItem(from: source.first!, to: destination)
                        }
                    }
                }
                .environment(\.editMode, $editMode)
                .listStyle(InsetGroupedListStyle())
                
                // Control buttons with improved touch targets
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.queueManager.clearQueue()
                    }) {
                        VStack {
                            Image(systemName: "trash")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                            Text("Clear")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        viewModel.queueManager.toggleShuffle()
                    }) {
                        VStack {
                            Image(systemName: viewModel.queueManager.shuffleEnabled ? "shuffle.circle.fill" : "shuffle")
                                .font(.title2)
                                .foregroundColor(viewModel.queueManager.shuffleEnabled ? .blue : .primary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                            Text("Shuffle")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        viewModel.queueManager.cycleRepeatMode()
                    }) {
                        VStack {
                            Image(systemName: {
                                switch viewModel.queueManager.repeatMode {
                                case .off: return "repeat"
                                case .all: return "repeat.circle.fill"
                                case .one: return "repeat.1.circle.fill"
                                }
                            }())
                            .font(.title2)
                            .foregroundColor(viewModel.queueManager.repeatMode == .off ? .primary : .blue)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                            
                            Text("Repeat")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        viewModel.playRandomPresetQueue()
                    }) {
                        VStack {
                            Image(systemName: "shuffle.circle")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                            Text("Random")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
            .navigationTitle("Queue")
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: EditButton()
            )
        }
    }
}

struct QueueView_Previews: PreviewProvider {
    static var previews: some View {
        QueueView()
            .environmentObject(LeBronifyViewModel())
    }
}

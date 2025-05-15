//
//  ContentView.swift
//  LeBronify
//
//  Created by Robert Wiscount on 3/26/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    var body: some View {
        ZStack {
            // Main content
            VStack(alignment: .leading, spacing: 20) {
                // Taco Tuesday Banner (only on Tuesdays)
                if TacoTuesdayManager.shared.isTacoTuesday {
                    TacoTuesdayBanner()
                }
                
                // Regular content
                VStack {
                    Image(systemName: "music.note.list")
                        .imageScale(.large)
                        .foregroundStyle(.yellow)
                        .font(.system(size: 60))
                    
                    Text("LeBronify Music")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .padding()
        }
    }
}

struct TacoTuesdayBanner: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("TACO TUESDAYYYYY")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange)
                )
                .shadow(radius: 5)
            
            Image(TacoTuesdayManager.shared.tacoTuesdayAlbumArt)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .cornerRadius(10)
                .shadow(radius: 5)
                .onTapGesture {
                    let tacoSong = TacoTuesdayManager.shared.createTacoTuesdaySong()
                    viewModel.playSong(tacoSong)
                }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LeBronifyViewModel())
    }
}

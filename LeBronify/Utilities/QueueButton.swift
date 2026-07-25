//
//  QueueButton.swift
//  LeBronify
//
//  Created by Robert Wiscount on 5/14/25.
//

import SwiftUI

struct QueueButton: View {
    @State private var showingQueue = false
    
    var body: some View {
        Button(action: {
            showingQueue = true
        }) {
            Image(systemName: "list.bullet")
                .font(.title3)
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .sheet(isPresented: $showingQueue) {
            QueueView()
        }
    }
}

struct RandomPresetQueueButton: View {
    @EnvironmentObject var viewModel: LeBronifyViewModel
    
    var body: some View {
        Button(action: {
            viewModel.playRandomPresetQueue()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Theme.brandGradient)
                        .frame(width: 70, height: 70)
                        .shadow(color: Theme.royal.opacity(0.4), radius: 6)
                    
                    Image(systemName: "shuffle.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 35, height: 35)
                        .foregroundColor(.white)
                }
                
                Text("Random Queue")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }
}

struct QueueButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            QueueButton()
                .previewLayout(.sizeThatFits)
                .padding()
            
            RandomPresetQueueButton()
                .environmentObject(LeBronifyViewModel())
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}

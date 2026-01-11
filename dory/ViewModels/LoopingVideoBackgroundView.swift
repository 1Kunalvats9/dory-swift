//
//  LoopingVideoBackgroundView.swift
//  dory
//
//  Created by Kunal Vats on 01/01/26.
//

import Foundation
import SwiftUI
import AVFoundation

struct LoopingVideoBackgroundView: UIViewRepresentable {

    let videoURL: URL
    var shouldPlay: Bool = true

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .black

        let player = AVPlayer(url: videoURL)
        player.isMuted = true
        player.actionAtItemEnd = .none

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
    
        context.coordinator.player = player
        context.coordinator.playerLayer = playerLayer
        context.coordinator.shouldPlay = shouldPlay

        containerView.layer.addSublayer(playerLayer)
        
   
        playerLayer.frame = UIScreen.main.bounds

       
        let observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            if context.coordinator.shouldPlay {
                player?.play()
            }
        }
        
      
        context.coordinator.observer = observer

        if shouldPlay {
            player.play()
        }

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update frame in case view size changed
        if let playerLayer = context.coordinator.playerLayer {
            // Use screen bounds to ensure full coverage
            playerLayer.frame = UIScreen.main.bounds
        }
        
       
        let wasPlaying = context.coordinator.shouldPlay
        context.coordinator.shouldPlay = shouldPlay
        
        if shouldPlay && !wasPlaying {
            context.coordinator.player?.play()
        } else if !shouldPlay && wasPlaying {
            context.coordinator.player?.pause()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var player: AVPlayer?
        var playerLayer: AVPlayerLayer?
        var shouldPlay: Bool = true
        var observer: NSObjectProtocol?
        
        deinit {
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

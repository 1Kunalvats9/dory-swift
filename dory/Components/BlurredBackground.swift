//
//  BlurredBackground.swift
//  dory
//
//  Created by Kunal Vats on 25/12/25.
//

import SwiftUI

struct BlurredBackground: View {
    var body: some View {
        ZStack{
            Image("bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    BlurredBackground()
}

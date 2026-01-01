//
//  HomeCard.swift
//  dory
//
//  Created by Kunal Vats on 27/12/25.
//

import SwiftUI

struct HomeCard: View {
    let text: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassEffectContainer {
                VStack(alignment: .leading, spacing: 12) {

                    Image(systemName: icon)
                        .font(.system(size: 42))
                        .foregroundColor(.orange)
                        .padding(.horizontal)

                    Text(text)
                        .font(.system(size: 24, weight: .light))
                        .frame(width: 160)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .frame(width: 200)
            .glassEffect(.clear, in: .rect(cornerRadius: 44))
        }
        .buttonStyle(.plain)
    }
}
//
//#Preview {
//    HomeCard(text:"this is a subheading of heading", icon:"plus.circle.fill")
//}

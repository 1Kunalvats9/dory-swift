//
//  Example.swift
//  dory
//
//  Created by Kunal Vats on 28/12/25.
//

import SwiftUI

struct Example: View {
    var body: some View {
        ZStack {
            BlurredBackground()
            ScrollView(.horizontal, showsIndicators: false){
                HStack{
//                    HomeCard(heading: "heading1", subHeading: "subheading of heading1", icon: "plus.circle.fill")
//                    HomeCard(heading: "heading1", subHeading: "subheading of heading1", icon: "plus.circle.fill")
                }
            }
            .padding()
            .frame(width:410)
        }
    }
}


#Preview {
    Example()
}

//
//  TextIngestView.swift
//  dory
//
//  Created by Kunal Vats on 28/12/25.
//

import SwiftUI

struct TextIngestView: View {
    
    @ObservedObject var viewModel: TextViewModel
    let onClose: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            
            TextField("Enter your text…", text: $viewModel.text)
                .padding()
                .glassEffect()
                .frame(width: 300)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(width: 50, height: 50)
            } else {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 28))
                    .frame(width: 50, height: 50)
                    .glassEffect(.clear.interactive())
                    .onTapGesture {
                        Task {
                            await viewModel.ingest()
                            if viewModel.errorMessage == nil {
                                onClose()
                            }
                        }
                    }
            }
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom))
    }
}

//#Preview {
//    TextIngestView()
//}

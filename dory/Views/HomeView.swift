//
//  HomeView.swift
//  dory
//
//  Created by Kunal Vats on 25/12/25.
//

import SwiftUI
internal import UniformTypeIdentifiers


struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isExpanded = false
    @State private var isTextMode = false
    @State private var showChat = false

    @StateObject private var ingestViewModel = TextViewModel()
    @StateObject private var pdfIngestViewModel = PDFIngestViewModel()
    @StateObject private var voiceInputViewModel = SpeechInputViewModel()
    
    @State private var showPDFPicker = false
    @State private var selectedPDFURL: URL?
    @State private var showVoiceBlob = false


    @Namespace var namespace
    
    var body: some View {
       NavigationStack {
           ZStack {
               BlurredBackground()
                   .ignoresSafeArea()
               
               VStack(alignment:.leading, spacing: 0){
                   HStack{
                       VStack(alignment:.leading){
                           Text("Hello, \(authViewModel.user?.displayName ?? "there")")
                               .font(.system(size: 40, weight:.light))
                               .italic()
                           
                           Text("What are we going to do today?")
                               .font(.system(size: 40, weight:.bold))
                       }
                       
                       Spacer()
                   }
                   .padding(.top,30)
                   .padding(.bottom,20)
                   .padding(.horizontal)
                   .frame(width:410)
                   
                   
                   ScrollView(.horizontal, showsIndicators: false){
                       HStack{
                           HomeCard(
                               text: "Ask your docs about your info",
                               icon: "message.fill"
                           ) {
                               showChat = true
                           }

                           HomeCard(text: "subheading of heading2", icon: "plus.circle.fill"){
                               
                           }
                       }
                   }
                   .padding()
                   .frame(width:410)
                   
                   
                   HStack {
                       if isExpanded{
                           
                           Group{
                               VStack {
                                   Image(systemName: "text.document.fill")
                                       .font(.system(size: 36))
                                       .padding(20)
                                       .frame(width:60,height:60)
                                       .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 20))
                                       .onTapGesture {
                                           withAnimation(.easeInOut(duration: 0.2)) {
                                               isExpanded = false
                                               isTextMode = true
                                           }
                                       }
                                   
                                   Text("Text")
                               }
                               
                               
                               
                               VStack {
                                   Image(systemName: "document.fill")
                                       .font(.system(size: 36))
                                       .padding(20)
                                       .frame(width: 60, height: 60)
                                       .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 20))
                                       .onTapGesture {
                                           withAnimation(.easeInOut(duration: 0.2)) {
                                               isExpanded = false
                                           }
                                           showPDFPicker = true
                                       }

                                   Text("PDF")
                               }

                               
                               
                               VStack{
                                   Image(systemName: "waveform")
                                       .font(.system(size: 36))
                                       .padding(20)
                                       .frame(width:60,height:60)
                                       .glassEffect(.clear.interactive(), in:.rect(cornerRadius: 20))
                                       .glassEffectID("text", in: namespace)
                                       .glassEffectTransition(.matchedGeometry)
                                       .onTapGesture {
                                           withAnimation(.easeIn(duration:0.2)){
                                               isExpanded = false
                                           }
                                           showVoiceBlob = true
                                       }
                                   Text("Audio")
                               }
                               
                           }
                           
                       }
                       VStack{
                           Image(systemName: "icloud.and.arrow.down.fill")
                               .padding(20)
                               .glassEffect(.clear.interactive())
                               .onTapGesture {
                                   guard !isTextMode else { return }
                                   withAnimation(.linear(duration: 0.15)){
                                       isExpanded.toggle()
                                   }
                               }
                           
                           Text("Save")
                       }
                       
                   }
                   .frame(width:410)
                   .padding(.vertical,48)
                   
                   
                   Spacer()
                   
                   if isTextMode {
                       TextIngestView(
                           viewModel: ingestViewModel,
                           onClose: {
                               withAnimation(.easeInOut(duration: 0.2)) {
                                   isTextMode = false
                               }
                           }
                       )
                   }
                   
                   
               }
               
               if case .uploading = pdfIngestViewModel.state {
                   VStack{
                       ProgressView("Uploading PDF…")
                           .padding()
                           .glassEffect(.clear.interactive())
                       Button("Okay"){
                           pdfIngestViewModel.state = .idle
                       }
                       .glassEffect(.clear.interactive())
                   }

               }

               if case .processing = pdfIngestViewModel.state {
                   VStack {
                       ProgressView("Processing PDF in background…")
                           .padding()
                           .glassEffect(.clear.interactive())
                       Button("Okay"){
                           pdfIngestViewModel.state = .idle
                       }
                       .glassEffect(.clear.interactive())
                   }

               }

               if case .completed = pdfIngestViewModel.state {
                   VStack{
                       Text("PDF ready to chat!")
                           .padding()
                           .glassEffect(.clear.interactive())
                       Button("Okay"){
                           pdfIngestViewModel.state = .idle
                       }
                       .glassEffect(.clear.interactive())
                   }
               }

               if case .failed(let message) = pdfIngestViewModel.state {
                   VStack{
                       Text(message)
                           .foregroundColor(.red)
                           .padding()
                       Button("Okay"){
                           pdfIngestViewModel.state = .idle
                       }
                       .glassEffect(.clear.interactive())
                   }

               }
               
               if showVoiceBlob {
        
                   AIVoiceInputBlob(
                       viewModel: voiceInputViewModel,
                       onClose: {
                           withAnimation(.easeOut(duration: 0.2)) {
                               showVoiceBlob = false
                           }
                       }
                   )
                   .frame(width: 410, height:800)
                   .ignoresSafeArea()
               }


           }
           .fileImporter(
               isPresented: $showPDFPicker,
               allowedContentTypes: [.pdf],
               allowsMultipleSelection: false
           ) { result in
               switch result {
               case .success(let urls):
                   guard let pdfURL = urls.first else { return }
                   selectedPDFURL = pdfURL
                   pdfIngestViewModel.uploadPDF(fileURL: pdfURL)

               case .failure(let error):
                   print("PDF selection failed:", error)
               }
           }

           .toolbar {
               ToolbarItem(placement: .navigationBarTrailing) {
                   Menu {
                       Button {
                           //settings
                       } label: {
                           Label("Settings", systemImage: "gearshape.fill")
                       }
                       
                       Button(role: .destructive) {
                           authViewModel.signOut()
                       } label: {
                           Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                       }
                   } label: {
                       AsyncImage(url: URL(string: authViewModel.user?.profilePhoto ?? "")) { phase in
                           switch phase {
                           case .empty:
                               ProgressView()
                                   .frame(width: 36, height: 36)
                                   .clipShape(Circle())
                               
                           case .success(let image):
                               image
                                   .resizable()
                                   .scaledToFill()
                                   .frame(width: 36, height: 36)
                                   .clipShape(Circle())
                                   .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                               
                           case .failure:
                               Image(systemName: "person.fill")
                                   .foregroundColor(.white)
                                   .frame(width: 36, height: 36)
                                   .background(Color.gray.opacity(0.3))
                                   .clipShape(Circle())
                               
                           @unknown default:
                               EmptyView()
                           }
                       }
                   }
               }
           }
           .navigationDestination(isPresented: $showChat) {
               ChatView()
           }

       }

        
    }
}


#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}

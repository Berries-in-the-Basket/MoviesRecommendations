//
//  ContentView.swift
//  MoviesRecommendation
//
//  Created by Mariusz Smoliński on 13.05.25.
//

import SwiftUI

struct ContentView: View {
    @State private var userInput: String = ""
    @State private var embedding: [Double] = []
    @State private var embeddings: [[Double]] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var matches: [SupabaseManager.MatchDocument] = []
    @State private var answer: String?
    
    @State private var podcasts: [String] = [
        "Beyond Mars (1 hr 15 min): Join space enthusiasts as they speculate about extraterrestrial life and the mysteries of distant planets.",
          "Jazz under stars (55 min): Experience a captivating night in New Orleans, where jazz melodies echo under the moonlit sky.",
          "Mysteries of the deep (1 hr 30 min): Dive with marine explorers into the uncharted caves of our oceans and uncover their hidden wonders.",
          "Rediscovering lost melodies (48 min): Journey through time to explore the resurgence of vinyl culture and its timeless appeal.",
          "Tales from the tech frontier (1 hr 5 min): Navigate the complex terrain of AI ethics, understanding its implications and challenges.",
          "The soundscape of silence (30 min): Traverse the globe with sonic explorers to find the world's most serene and silent spots.",
          "Decoding dreams (1 hr 22 min): Step into the realm of the subconscious, deciphering the intricate narratives woven by our dreams.",
          "Time capsules (50 min): Revel in the bizarre, endearing, and profound discoveries that unveil the quirks of a century past.",
          "Frozen in time (1 hr 40 min): Embark on an icy expedition, unearthing secrets hidden within the majestic ancient glaciers.",
          "Songs of the Sea (1 hr): Dive deep with marine biologists to understand the intricate whale songs echoing in our vast oceans."
    ]
    
    private let embeddingsManager = OpenAIEmbeddingsManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("What do you want to watch?", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    Task {
//                        await generateEmbeddingForUserQuery(query: userInput)
                        let vectorFound = try await SupabaseManager.shared.getNearestVectorFor(query: userInput)
                        answer = vectorFound.first?.content ?? "No answer found"
                    }
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Generate Answer")
                            .foregroundColor(Color(red: 84/255, green: 22/255, blue: 144/255))
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 255/255, green: 205/255, blue: 56/255))
                            .cornerRadius(8)
                    }
                }
                .disabled(userInput.isEmpty || isLoading)
                .padding(.horizontal)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                if let answer = answer {
                    Text(answer)
                        .padding()
                }
                
                
                List(matches, id: \.self) { match in
                                    VStack(alignment: .leading) {
                                        Text(match.content)
                                            .font(.body)
                                        if let score = match.similarity {
                                            Text(String(format: "Score: %.4f", score))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                
                if !embedding.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text("Embedding Result (\(embedding.count) dimensions):")
                                .font(.subheadline)
                                .bold()
                                .padding(.bottom, 5)
                            
                            Text(embedding.map { String(format: "%.4f", $0) }.joined(separator: ", "))
                                .font(.caption)
                                .padding(.horizontal)
                            
                            Text(answer ?? "test vector")
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Movies")
        }
    }
    
    @MainActor
    private func generateAndSaveEmbedding() async {
        errorMessage = nil
        embeddings = []
        isLoading = true
        
        do {
            var rows: [SupabaseManager.EmbeddingRow] = []
            for podcast in podcasts{
                let vector = try await embeddingsManager.fetchEmbedding(for: podcast)
                embeddings.append(vector)
                rows.append(SupabaseManager.EmbeddingRow(content: podcast, embedding: vector))
            }
            //let vector = try await embeddingsManager.fetchEmbedding(for: userInput)
            //embedding = vector
            try await SupabaseManager.shared.saveEmbeddings(rows)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    private func generateEmbeddingForUserQuery(query: String) async {
        errorMessage = nil
        embeddings = []
        isLoading = true
        
        do{
            let vector = try await embeddingsManager.fetchEmbedding(for: userInput)
            embedding = vector
        }catch{
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    ContentView()
}

//
//  SupabaseManager.swift
//  MoviesRecommendation
//
//  Created by Mariusz Smoliński on 13.05.25.
//

import Foundation
import Supabase

public class SupabaseManager {
    static let shared = SupabaseManager()
    private let client: SupabaseClient
    private let embeddingsManager: OpenAIEmbeddingsManager
    
    private init() {
        let url = URL(string: APIKeys.supabaseURL)
        let key = APIKeys.supabaseAPIKey
        client = SupabaseClient(supabaseURL: url!, supabaseKey: key)
        embeddingsManager = OpenAIEmbeddingsManager()
    }
    
    struct EmbeddingRow: Codable {
        let content: String
        let embedding: [Double]
    }
    
    struct MatchDocument: Codable, Hashable {
        let id: Int64
        let content: String
        //        let embedding: [Double]?
        let similarity: Float?
    }
    
    struct MatchDocumentsParams: Codable {
        let query_embedding_text: String
        let match_threshold: Float
        let match_count: Int
    }
    
    func saveEmbedding(text: String, vector: [Double]) async throws {
        let row = EmbeddingRow(content: text, embedding: vector)
        let response = try await client.from("documents")
            .insert(row)
            .execute()
        //add error handling
        
        //        if let error = response. {
        //            throw EmbeddingError.requestFailed
        //        }
    }
    
    func saveEmbeddings(_ rows: [EmbeddingRow]) async throws {
        let response = try await client.from("documents")
            .insert(rows)
            .execute()
        
        //            if let _ = response.error {
        //                throw EmbeddingError.saveFailed
        //            }
    }
    
    //implements the notion of similarity search
    func getNearestVectorFor(query: String) async throws -> [MatchDocument] {
        
        let vector = try await embeddingsManager.fetchEmbedding(for: query)
        
        print(vector)
        print(vector.count)
        
        let queryEmbeddingAsString = vector.map{ String($0) }.joined(separator: ",")
        
        print("VERCTOR AS STRING: \n")
        print(queryEmbeddingAsString)
        
        let response: [MatchDocument] = try await client
            .rpc("match_documents",
                 params: MatchDocumentsParams(query_embedding_text: queryEmbeddingAsString, match_threshold: 0.5, match_count: 1))
            .execute()
            .value
        
        print("NEAREST VECTOR: \n")
        print(response)
        return response
    }
}





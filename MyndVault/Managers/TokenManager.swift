//
//  TokenManager.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 30.04.24.
//

import Foundation

struct TokenUsage: Codable {
    var openAITokens: Int
    var pineconeReadUnits: Int
    var pineconeWriteUnits: Int
}

enum APIs {
    case openAI
    case pinecone
}

func updateTokenUsage(api: APIs, tokensUsed: Int, read:Bool) {
    
    let userDefaults = UserDefaults.standard
    let decoder = PropertyListDecoder()
    let encoder = PropertyListEncoder()
    
    var usage: TokenUsage
    if let data = userDefaults.data(forKey: "APITokenUsage"),
       let decodedUsage = try? decoder.decode(TokenUsage.self, from: data) {
        usage = decodedUsage
    } else {
        usage = TokenUsage(openAITokens: 0, pineconeReadUnits: 0, pineconeWriteUnits: 0)
    }

    switch api {
       case .openAI:
           usage.openAITokens += tokensUsed
       case .pinecone:
           if read {
               usage.pineconeReadUnits += tokensUsed
           } else {
               usage.pineconeWriteUnits += tokensUsed
           }
       }
    
    if let encodedData = try? encoder.encode(usage) {
        userDefaults.set(encodedData, forKey: "APITokenUsage")
    }
}

func printTokenUsage() {
    let userDefaults = UserDefaults.standard
    let decoder = PropertyListDecoder()
    
    if let data = userDefaults.data(forKey: "APITokenUsage"),
       let usage = try? decoder.decode(TokenUsage.self, from: data) {
        print("""
              Total Tokens consumed so far:
              OpenAI-> \(usage.openAITokens)
              Pinecone (Read)-> \(usage.pineconeReadUnits)
              Pinecone (Write)-> \(usage.pineconeWriteUnits)
              """)
    } else {
        print("Failed to retrieve token usage.")
    }
}

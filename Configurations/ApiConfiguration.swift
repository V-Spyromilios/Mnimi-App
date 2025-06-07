//
//  ApiConfiguration.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 05.02.24.
//

import Foundation

struct ApiConfiguration {
    
    static var catKey: String? {
        guard let path = Bundle.main.path(forResource: "OpenAIKey", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path),
              let apiKey = dictionary["REVENUE_KEY"] as? String
        else {
            return nil
        }
        return apiKey
    }

    static var openAIKey: String? {
        guard let path = Bundle.main.path(forResource: "OpenAIKey", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path),
              let apiKey = dictionary["OPENAI_API_KEY"] as? String
        else {
            return nil
        }
        return apiKey
    }
    
    
    static var pineconeKey: String? {
        guard let path = Bundle.main.path(forResource: "OpenAIKey", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path),
              let apiKey = dictionary["PINECONE_KEY"] as? String
        else {
            return nil
        }
        return apiKey
    }
    

}

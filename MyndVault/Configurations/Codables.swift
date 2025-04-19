//
//  Codables.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 12.02.24.
//

import Foundation

//MARK: audio to text
struct WhisperResponse: Codable {
    let text: String
}

//MARK: TRANSRIPT RESPONSE
struct TranscriptionResponse: Codable {
    
    let response: String
    
    enum CodingKeys: String, CodingKey {
        case response = "text"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.response = try container.decode(String.self, forKey: .response)
    }
}

//MARK: RESPONSE FROM ANALYIZNG TRANSCRIPT
// ✅ Top-level OpenAI API response structure
struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

// ✅ Array of choices (OpenAI usually returns 1 choice)
struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

// ✅ Contains the actual JSON (wrapped in a code block)
struct OpenAIMessage: Codable {
    let content: String
    
    // ✅ Custom decoding to extract JSON from markdown code block
    var extractedJSON: String {
        if content.hasPrefix("```json") {
            return content
                .replacingOccurrences(of: "```json\n", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return content
    }
}

enum IntentType: String, Codable {
    case isQuestion = "is_question"
    case isReminder = "is_reminder"
    case isCalendar = "is_calendar"
    case saveInfo = "save_info"
    case unknown
}

struct IntentClassificationResponse: Codable, Equatable {
    let type: IntentType
    let query: String?
    let task: String?
    let datetime: String?
    let title: String?
    let location: String?
    let memory: String?
    
    static func == (lhs: IntentClassificationResponse, rhs: IntentClassificationResponse) -> Bool {
        return lhs.type == rhs.type &&
        lhs.query == rhs.query &&
        lhs.task == rhs.task &&
        lhs.datetime == rhs.datetime &&
        lhs.title == rhs.title &&
        lhs.location == rhs.location &&
        lhs.memory == rhs.memory
    }

    enum CodingKeys: String, CodingKey {
        case type, query, task, datetime, title, location, memory
    }


    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.type = (try? container.decode(IntentType.self, forKey: .type)) ?? .unknown
        self.query = try? container.decode(String.self, forKey: .query)
        self.task = try? container.decode(String.self, forKey: .task)
        self.datetime = try? container.decode(String.self, forKey: .datetime)
        self.title = try? container.decode(String.self, forKey: .title)
        self.location = try? container.decode(String.self, forKey: .location)
        self.memory = try? container.decode(String.self, forKey: .memory)
    }
}

//MARK: GPT RESPONSE
struct ChatCompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let systemFingerprint: String?
    let choices: [Choice]
    let usage: Usage
    
    enum CodingKeys: String, CodingKey {
        case id, object, created, model, choices, usage
        case systemFingerprint = "system_fingerprint"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.object = try container.decode(String.self, forKey: .object)
        self.created = try container.decode(Int.self, forKey: .created)
        self.model = try container.decode(String.self, forKey: .model)
        self.systemFingerprint = try container.decodeIfPresent(String.self, forKey: .systemFingerprint)
        self.choices = try container.decode([Choice].self, forKey: .choices)
        self.usage = try container.decode(Usage.self, forKey: .usage)
    }
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let logprobs: Bool?
        let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case index, message, logprobs
            case finishReason = "finish_reason"
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.finishReason = try container.decode(String.self, forKey: .finishReason)
            self.index = try container.decode(Int.self, forKey: .index)
            self.message = try container.decode(Message.self, forKey: .message)
            self.logprobs = try container.decodeIfPresent(Bool.self, forKey: .logprobs)
        }
        
    }
    
    struct Message: Codable {
        let role: String
        let content: String
        
        enum CodingKeys: String, CodingKey {
            case role, content
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.content = try container.decode(String.self, forKey: .content)
            self.role = try container.decode(String.self, forKey: .role)
        }
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.completionTokens = try container.decode(Int.self, forKey: .completionTokens)
            self.promptTokens = try container.decode(Int.self, forKey: .promptTokens)
            self.totalTokens = try container.decode(Int.self, forKey: .totalTokens)
        }
    }

}

// EXTRa to the ChatCompletionResponse
struct MetadataResponse: Codable {
    var type: String
    var description: String
    var relevantFor: String
    var fileUrl: URL?
    var date: String?
    var time: String?
    
    enum CodingKeys: String, CodingKey {
        case type, description, relevantFor, date, time
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.description = try container.decode(String.self, forKey: .description)
        self.type = try container.decode(String.self, forKey: .type)
        self.relevantFor = try container.decodeIfPresent(String.self, forKey: .relevantFor) ?? "User"
        self.date = try container.decodeIfPresent(String.self, forKey: .date)
        self.time = try container.decodeIfPresent(String.self, forKey: .time)
    }
    
//    func toDictionary() -> [String: String] {
//            return [
//                "type": type,
//                "description": description,
//                "relevantFor": relevantFor
//            ]
//        }
}


//MARK: EMBEDDINGS
struct EmbeddingsResponse: Codable {
    let object: String
    let data: [EmbeddingObject]
    let model: String
    let usage: Usage
    
    enum CodingKeys: String, CodingKey {
        case object, data, model, usage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.object = try container.decode(String.self, forKey: .object)
        self.model = try container.decode(String.self, forKey: .model)
        self.data = try container.decode([EmbeddingObject].self, forKey: .data)
        self.usage = try container.decode(Usage.self, forKey: .usage)
    }
}

struct EmbeddingObject: Codable {
    let object: String
    let embedding: [Float]
    let index: Int
    
    enum CodingKeys: String, CodingKey {
        case object, embedding, index
    }
    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.embedding = try container.decode([Float].self, forKey: .embedding)
//        self.index = try container.decode(Int.self, forKey: .index)
//        self.object = try container.decode(String.self, forKey: .object)
//    }
}

struct Usage: Codable, Equatable {
    let promptTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case totalTokens = "total_tokens"
    }
    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.promptTokens = try container.decode(Int.self, forKey: .promptTokens)
//        self.totalTokens = try container.decode(Int.self, forKey: .totalTokens)
//    }
}

//MARK: Pinecone Query Response
struct PineconeQueryResponse: Codable, Equatable {
    let matches: [Match]
    let usage: PineconeSingleUsage
    
    enum CodingKeys: String, CodingKey {
        case matches, usage
    }
}
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.matches = try container.decode([Match].self, forKey: .matches)
//        self.usage = try container.decode(PineconeSingleUsage.self, forKey: .usage)
//    }
    
//    func getMatchesDescription() -> [String] {
//            var descriptions: [String] = []
//
//            for match in matches {
//                debugLog("Matches : \(String(describing: match.metadata))")
//                debugLog("Match id : \(match.id)")
//                if let description = match.metadata?["description"] { // Extract the "description" value from each match's metadata
//                    descriptions.append(description)
//                }
//                if let timestamp = match.metadata?["timestamp"] {
//                    descriptions.append(timestamp)
//                } else { print("No timestamp found for match: \(match.id)") }
//            }
//
//            return descriptions
//        }


struct Match: Codable, Equatable {
    let id: String
    let score: Double
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, score, metadata
    }

}

struct PineconeSingleUsage: Codable, Equatable {
        let readUnits: Int

    }


//MARK: to fetch Pinecone IDs of entries, to use this to get the saved info/metadata.
struct PineconeIDResponse: Codable {
    let vectors: [Vector]
    let pagination: Pagination?
    let namespace: String
    let usage: PineconeUsage
    
    enum CodingKeys: String, CodingKey {
        case vectors, pagination, namespace, usage
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.vectors = try container.decode([Vector].self, forKey: .vectors)
        self.pagination = try container.decodeIfPresent(Pagination.self, forKey: .pagination)
        self.namespace = try container.decode(String.self, forKey: .namespace)
        self.usage = try container.decode(PineconeUsage.self, forKey: .usage)
    }
    
    
    struct Vector: Codable {
        let id: String
        
        enum CodingKeys: String, CodingKey {
            case id
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(String.self, forKey: .id)
        }
    }
    
    struct Pagination: Codable {
        let next: String
        
        enum CodingKeys: String, CodingKey {
            case next
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.next = try container.decode(String.self, forKey: .next)
        }
    }
    
    struct PineconeUsage: Codable {
        let readUnits: Int
        
        enum CodingKeys: String, CodingKey {
            case readUnits
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.readUnits = try container.decode(Int.self, forKey: .readUnits)
        }
    }
}

//MARK: PineconeFetchResponseFromID
struct PineconeFetchResponseFromID: Codable {
    var vectors: [String: Vector]
    
    enum CodingKeys: String, CodingKey {
        case vectors
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.vectors = try container.decode([String: Vector].self, forKey: .vectors)
    }
}

struct Vector: Codable, Hashable, Identifiable {

    let id: String
    var metadata: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case id, metadata
    }
    
    init(id: String, metadata: [String: String]) {
            self.id = id
            self.metadata = metadata
        }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.metadata = try container.decode([String: String].self, forKey: .metadata)
    }
}

//struct SparseValues: Codable {
//    let indices: [Int]
//    let values: [Double]
//}
//    
//    // Define the structure for usage
//    struct FetchResponseUsage: Codable {
//        let readUnits: Int
//        
//        enum CodingKeys: String, CodingKey {
//            case readUnits
//        }
//    }

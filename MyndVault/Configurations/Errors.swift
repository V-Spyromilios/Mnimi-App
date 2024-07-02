//
//  AppError.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 22.02.24.
//

import Foundation


enum AppNetworkError: Error {
    case apiKeyNotFound
       case invalidOpenAiURL
       case invalidResponse
       case noChoicesInResponse
       case invalidTTSURL
       case serializationError(String)
       case unknownError(String)

       var errorDescription: String {
           switch self {
           case .apiKeyNotFound:
               return "API Key not found."
           case .invalidOpenAiURL:
               return "Invalid OpenAi URL."
           case .invalidResponse:
               return "Invalid response from server."
           case .noChoicesInResponse:
               return "No choices found in GPT response."
           case .invalidTTSURL:
               return "Invalid Text-to-Speech URL."
           case .serializationError(let message):
               return "Serialization error: \(message)"
           case .unknownError(let message):
               return "Unknown error: \(message)"
           }
       }
}

enum AppCKError: LocalizedError {
    case iCloudAccountNotFound
    case iCloudAccountNotDetermined
    case iCloudAccountRestricted
    case iCloudAccountUknown
    case iCloudTemporarilyUnavailable
    case unknownError(message: String)
    case UnableToGetNameSpace
    case CKDatabaseNotInitialized
    case imageConversionFailed
    case recordNotFound

    var errorDescription: String {
        switch self {
        case .iCloudAccountNotDetermined:
            return "iCloud Account not Determined."
        case .iCloudAccountNotFound:
            return "iCloud Account not Found."
        case .iCloudAccountRestricted:
            return "iCloud Account is Restricted."
        case .iCloudAccountUknown:
            return "Unknown iCloud Account."
        case .iCloudTemporarilyUnavailable:
            return "iCloud Account Temporarily Unavailable."
        case .UnableToGetNameSpace:
            return "Unable To retrieve namespace."
        case .unknownError(let message):
            return "Unknown Error Occurred : \(message)"
        case .CKDatabaseNotInitialized:
            return "CK Database not initialized."
        case .imageConversionFailed:
            return "Image Convertion failed"
        case .recordNotFound:
            return "CK Record not found."
        }
    }
}

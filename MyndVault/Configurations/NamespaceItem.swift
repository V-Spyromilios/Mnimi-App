//
//  NamespaceItem.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 06.03.24.
//

//import Foundation
//import CloudKit
//
//struct NamespaceItem {
//    var recordID: CKRecord.ID
//    let namespace: String
//}
//
////representation of NamespaceItem in terms of required record
//extension NamespaceItem {
//    var record: CKRecord {
//        let record = CKRecord(recordType: "NamespaceItem", recordID: recordID)
//        record["namespace"] = namespace as CKRecordValue
//        return record
//    }
//}
//
//extension NamespaceItem {
//    init?(record: CKRecord) {
//        guard let ns = record["namespace"] as? String else {
//            debugLog("init of NamespaceItem:: 'guard let ns = ' FAILED")
//            return nil
//        }
//        self.init(recordID: record.recordID, namespace: ns)
//    }
//}

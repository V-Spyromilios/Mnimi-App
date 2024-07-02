//
//  ImageItem.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 27.06.24.
//

import Foundation
import CloudKit

struct ImageItem {
    var recordID: CKRecord.ID?
    let imageAsset: CKAsset
    let uniqueID: String

    var record: CKRecord {
        let record = CKRecord(recordType: "ImageItem", recordID: recordID ?? CKRecord.ID())
        record["imageAsset"] = imageAsset
        record["uniqueID"] = uniqueID as CKRecordValue
        return record
    }
}

extension ImageItem {
    init?(record: CKRecord) {
        guard let imageAsset = record["imageAsset"] as? CKAsset,
              let uniqueID = record["uniqueID"] as? String else {
            return nil
        }
        print("ImageItem init -> Image Asset: \(imageAsset.description)\n-> uniqueID: \(uniqueID)")
        self.init(recordID: record.recordID, imageAsset: imageAsset, uniqueID: uniqueID)
    }
}

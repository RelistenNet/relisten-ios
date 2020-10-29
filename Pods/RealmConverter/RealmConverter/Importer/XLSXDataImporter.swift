////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#if os(OSX)
import Foundation
import PathKit
import Realm
import TGSpreadsheetWriter

@objc(RLMXLSXDataImporter)
open class XLSXDataImporter: DataImporter {

    open override func `import`(toPath path: String, schema: ImportSchema) throws -> RLMRealm {
        let realm = try! self.createNewRealmFile(atPath: path, schema: schema)
        
        let workbook = TGSpreadsheetWriter.readWorkbook(URL(fileURLWithPath: "\(Path(files[0]).absolute())")) as! [String: [[String]]]
        for (_, key) in workbook.keys.enumerated() {
            if let curSchema = schema.schemaWithName(key) {
            
                if let sheet = workbook[key] {
                    let rows = sheet.dropFirst()
                    for row in rows {
                        let cls = NSClassFromString(curSchema.objectClassName) as! RLMObject.Type
                        let object = cls.init()
                        
                        row.enumerated().forEach { (fieldIndex, field) -> () in
                            let property = curSchema.properties[fieldIndex]
                            
                            switch property.type {
                            case .int:
                                if let number = Int64(field) {
                                    object.setValue(NSNumber(value: number), forKey: property.originalName)
                                }
                            case .double:
                                if let number = Double(field) {
                                    object.setValue(NSNumber(value: number), forKey: property.originalName)
                                }
                            default:
                                object.setValue(field, forKey: property.originalName)
                            }
                        }

                        try realm.transaction { () -> Void in
                            realm.add(object)
                        }
                    }
                }
            } else {
                throw NSError(domain: "io.realm.converter.error", code: 0, userInfo: nil)
            }
        }
        
        return realm
    }
}
#endif

//
//  Data+IPaURLResourceUI.swift
//  IPaURLResourceUI
//
//  Created by IPa Chen on 2020/7/20.
//

import UIKit
import IPaLog
import IPaXMLSection

extension Data {
    fileprivate func removeNSNullDataFromObject(_ object:Any) -> Any
    {
        if let dictObject = object as? [String:Any] {
            return removeNSNullDataFromDictionary(dictObject) as Any
        }
        else if let arrayValue = object as? [Any] {
            return removeNSNullDataFromArray(arrayValue) as Any
        }
        return object
    }
    fileprivate func removeNSNullDataFromDictionary(_ dictionary:[String:Any]) -> [String:Any]
    {
        var mDict = [String:Any]()
        
        for key in dictionary.keys {
            let value = dictionary[key] as Any
            if let _ = value as? NSNull {
                continue;
            }
            else if let dictValue = value as? [String:Any] {
                mDict[key] = removeNSNullDataFromDictionary(dictValue) as Any
            }
            else if let arrayValue = value as? [Any] {
                mDict[key] = removeNSNullDataFromArray(arrayValue) as Any
            }
            mDict[key] = dictionary[key]
        }
        return mDict;
    }
    fileprivate func removeNSNullDataFromArray(_ array:[Any]) -> [Any]
    {
        var mArray = [Any]()
        for value in array {
            var newValue:Any = value;
            if value is NSNull {
                continue;
            }
            else if let dictValue = value as? [String:Any] {
                newValue = removeNSNullDataFromDictionary(dictValue) as Any
            }
            else if let arrayValue = value as? [Any] {
                newValue = removeNSNullDataFromArray(arrayValue) as Any
            }
            mArray.append(newValue)
            
        }
        return mArray;
    }
    public var jsonData:Any? {
        guard let jsonData = try? JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions()) else {
            return nil
        }
        return self.removeNSNullDataFromObject(jsonData)
    }
    public var xmlData:Any? {
        guard let section = IPaXMLSection(self) else {
            return nil
        }
        return section.jsonObject
    }
    public func decodeJson<T:Codable>(_ type:T) throws -> T {
        let jsonDecoder = JSONDecoder()
        return try jsonDecoder.decode(T.self, from: self)
    }
}

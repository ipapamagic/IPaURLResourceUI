//
//  IPaURLResponseHandler.swift
//  IPaURLResourceUI
//
//  Created by IPa Chen on 2020/7/20.
//

import UIKit
import IPaLog
import IPaXMLSection
public protocol IPaURLResponseHandler {
    func handleResponse(_ responseData: Data, response: URLResponse) -> Any?
}
extension IPaURLResponseHandler {
    func removeNSNullDataFromObject(_ object:Any) -> Any
    {
        if let dictObject = object as? [String:Any] {
            return removeNSNullDataFromDictionary(dictObject) as Any
        }
        else if let arrayValue = object as? [Any] {
            return removeNSNullDataFromArray(arrayValue) as Any
        }
        return object;
    }
    func removeNSNullDataFromDictionary(_ dictionary:[String:Any]) -> [String:Any]
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
    func removeNSNullDataFromArray(_ array:[Any]) -> [Any]
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
}
open class IPaURLJsonResponseHandler :NSObject,IPaURLResponseHandler {
    public func handleResponse(_ responseData: Data, response: URLResponse) -> Any? {
             
//            #if DEBUG
//            let urlString = response.url?.absoluteString ?? ""
//            if let retString = String(data: responseData, encoding: .utf8){
//                
//                print("IPaURLResourceUI request from:\(urlString), return string :\(retString)")
//            }
//            #endif
            do {
            
                var jsonData = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions())
                
                
                jsonData = self.removeNSNullDataFromObject(jsonData)
                
                return jsonData
            
            } catch _ as NSError {
                var responseString:String = ""
                let urlString = response.url?.absoluteString ?? ""
                if let string = String(data: responseData, encoding: String.Encoding.utf8) {
                    
                    IPaLog("Request from:\(urlString) \n not json response with:" + string)
                    responseString = string
                }
                    //try ascii if decode fail
                else if let string = String(data: responseData, encoding: String.Encoding.ascii) {
                    IPaLog("Request from:\(urlString) \n not json response with:" + string)
                    responseString = string
                }
                
    //                let notJsonError = NSError(domain: "IPaURLResourceUI", code: -1, userInfo: [NSLocalizedDescriptionKey:"Server response is not json format:\(responseString)"])
    //                failure(notJsonError)
    //
                
                return responseString
            } catch {
                fatalError()
            }
        }
}

open class IPaURLXMLResponseHandler:NSObject,IPaURLResponseHandler {
    public func handleResponse(_ responseData: Data, response: URLResponse) -> Any?
    {
        
        guard let section = IPaXMLSection(responseData) else {
            
            IPaLog(String(data: responseData, encoding: .utf8) ?? "")
            return nil
        }
        return section.jsonObject
    }
}

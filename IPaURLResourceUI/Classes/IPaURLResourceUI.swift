//
//  IPaURLResourceUI.swift
//  IPaURLResourceUI
//
//  Created by IPa Chen on 2015/6/12.
//  Copyright (c) 2015年 IPaPa. All rights reserved.
//

import Foundation
import IPaLog
import IPaNetworkState
public typealias IPaURLResourceUISuccessHandler = ((URLResponse?,Any?) -> ())
public typealias IPaURLResourceUIFailHandler = ((Error) -> ())
open class IPaURLResourceUI : NSObject,URLSessionDelegate {
    @objc open var baseURL:String! = ""
    @objc open var removeNSNull:Bool = true
    @objc open lazy var urlSession:URLSession = {
        weak var weakSelf = self
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: weakSelf, delegateQueue: OperationQueue.main)
        return session
    }()
    func urlStringForAPI(_ api:String) -> String {
        return self.baseURL + api
    }
    func urlStringForGETAPI(_ api:String!, param:[String:Any]?) -> String! {
        var apiURL = self.baseURL + api
        
        if let params = param {
            apiURL = apiURL + "?"
            var count = 0
            
            for key in params.keys {
                apiURL = apiURL + ((count > 0) ? "&":"") + "\(key)=\(params[key]!)"
                count += 1
            }
        }
        
        return ((apiURL as NSString).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed))!
        
        
        
        
    }
    func apiWithRequest(_ request:URLRequest,complete:@escaping IPaURLResourceUISuccessHandler,failure:@escaping IPaURLResourceUIFailHandler) -> URLSessionDataTask {
        IPaNetworkState.startNetworking()
        let task = urlSession.dataTask(with: request, completionHandler: { (responseData,response,error) in
            IPaNetworkState.endNetworking()
            if let error = error {
                failure(error)
                return
            }
            var jsonData:Any?
            do {
                if let responseData = responseData,responseData.count > 0 {
                    jsonData = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions())
                }
            } catch _ as NSError {
                jsonData = nil
                var responseString:String = ""
                
                if let string = String(data: responseData!, encoding: String.Encoding.utf8) {
                    IPaLog(string)
                    responseString = string
                }
                    //try ascii if decode fail
                else if let string = String(data: responseData!, encoding: String.Encoding.ascii) {
                    IPaLog(string)
                    responseString = string
                }
                
//                let notJsonError = NSError(domain: "IPaURLResourceUI", code: -1, userInfo: [NSLocalizedDescriptionKey:"Server response is not json format:\(responseString)"])
//                failure(notJsonError)
//
                complete(response,responseString)
            } catch {
                fatalError()
            }
            if self.removeNSNull,let wJsonData = jsonData {
                jsonData = self.removeNSNullDataFromObject(wJsonData)
            }
            complete(response,jsonData)
        })
        
        task.resume()
        
        return task
    }
    
    @objc open func apiGet(_ api:String ,param:[String:Any]?,complete:@escaping IPaURLResourceUISuccessHandler,failure:@escaping IPaURLResourceUIFailHandler) -> URLSessionDataTask
    {
        let apiURL = urlStringForGETAPI(api, param: param)
        let request = NSMutableURLRequest()
        request.httpMethod = "GET"
        request.url = URL(string: apiURL!)
        
        return apiWithRequest(request as URLRequest,complete:complete,failure:failure)
    }

    @objc open func apiPost(_ api:String , param:[String:Any]?,complete:@escaping IPaURLResourceUISuccessHandler,failure:@escaping IPaURLResourceUIFailHandler) -> URLSessionDataTask
    {
        return apiPerform(api,method:"POST",paramInBody:param,complete:complete,failure:failure)
    }
    
    @objc open func apiPut(_ api:String, param:[String:Any]?,complete:@escaping IPaURLResourceUISuccessHandler,failure:@escaping IPaURLResourceUIFailHandler) -> URLSessionDataTask {
        
        return apiPerform(api ,method:"PUT", paramInBody:param,complete:complete,failure:failure)
    }
    @objc open func apiUpload(_ api:String,method:String,json:Any,complete:@escaping IPaURLResourceUISuccessHandler,failure:@escaping IPaURLResourceUIFailHandler) {

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0))
            _ = apiUpload(api, method: method, headerParam: ["content-type":"application/json"], data: jsonData, complete: complete, failure: failure)
            
        }
        catch let error as NSError {
            failure(error)
            return
        }
        
        
        
    }
    @objc open func apiPerform(_ api:String,method:String,paramInHeader:[String:String]?,paramInBody:[String:Any]?,complete:@escaping IPaURLResourceUISuccessHandler,failure:@escaping IPaURLResourceUIFailHandler) -> URLSessionDataTask

    {
        let method = method.uppercased()
        let apiURL = (method == "GET") ? urlStringForGETAPI(api, param: paramInBody) :  urlStringForAPI(api)
        let request = NSMutableURLRequest()
        if let param = paramInBody , method != "GET" {
            var count = 0
            var postString = ""
            
            for key in param.keys {
                var value = "\(param[key]!)"
                let characterSet = NSMutableCharacterSet.alphanumeric()
                characterSet.addCharacters(in: "-._~")
                value = (value.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet))!
                
                postString = postString + ((count > 0) ? "&" : "") + "\(key)=\(value)"
                count += 1
                
            }
            request.httpBody = postString.data(using: String.Encoding.utf8, allowLossyConversion: false)
            
        }
        
        request.url = URL(string: apiURL!)
        request.httpMethod = method
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        if let param = paramInHeader {
            for key in param.keys {
                request.setValue(param[key]!,forHTTPHeaderField: key)
            }
        }
        
        
        return apiWithRequest(request as URLRequest,complete:complete,failure:failure)
        
        
    }

    @objc open func apiPerform(_ api:String,method:String,paramInBody:[String:Any]?,complete:@escaping IPaURLResourceUISuccessHandler,failure:@escaping IPaURLResourceUIFailHandler) -> URLSessionDataTask {
        return apiPerform(api, method: method, paramInHeader: nil, paramInBody: paramInBody, complete: complete, failure: failure)
        
    }
    @objc open func apiUpload(_ api:String,method:String,headerParam:[String:String],data:Data,complete:@escaping IPaURLResourceUISuccessHandler,failure:@escaping IPaURLResourceUIFailHandler) -> URLSessionUploadTask {
        let apiURL = urlStringForAPI(api)
        let request = NSMutableURLRequest()
        request.url = URL(string: apiURL)
        request.httpMethod = method
        
        for key in headerParam.keys {
            request.setValue(headerParam[key]!, forHTTPHeaderField: key)
            
        }
        //        [request setValue:contentType forHTTPHeaderField:@"content-type"]
        //    NSString *dataLength = [NSString stringWithFormat:@"%ld", (unsigned long)[data length]]
        //    [request setValue:dataLength forHTTPHeaderField:@"Content-Length"]
        //    [request setHTTPBody:data]
        IPaNetworkState.startNetworking()
        let task = urlSession.uploadTask(with: request as URLRequest, from: data, completionHandler: {
            (responseData,response,error) -> Void in
            IPaNetworkState.endNetworking()
            if let error = error {
                failure(error)
                return
            }
            
            #if DEBUG
                if let responseData = responseData ,let retString = String(data: responseData, encoding: .utf8){
                    
                    print("IPaURLResourceUI return string :\(retString)")
                }
            #endif
            var jsonData:Any?
            do {
                if let responseData = responseData {
                    jsonData = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions())
                }
            } catch let error as NSError {
                failure(error)
                return
            } catch {
                fatalError()
            }
            if self.removeNSNull {
                jsonData = self.removeNSNullDataFromObject(jsonData!)
            }
            complete(response,jsonData)
            
            
        })
        
        task.resume()
        return task
    }

    @objc open func apiUpload(_ api:String,method:String,multiPartFormData:IPaURLMultipartFormData,complete:@escaping IPaURLResourceUISuccessHandler,failure:@escaping IPaURLResourceUIFailHandler) -> URLSessionUploadTask {
        let contentType = "multipart/form-data boundary=\(multiPartFormData.boundary)"
        multiPartFormData.endOfBodyData()
        let data = multiPartFormData.data
        return apiUpload(api, method: method, headerParam: ["content-type":contentType], data: data as Data, complete: complete, failure: failure)
    }

    @objc open func apiPut(_ api:String,contentType:String,postData:Data,complete:@escaping IPaURLResourceUISuccessHandler,failure:@escaping IPaURLResourceUIFailHandler) -> URLSessionUploadTask {
        return apiUpload(api, method: "PUT", headerParam: ["content-type":contentType], data: postData, complete: complete, failure: failure)
    }
    @objc open func apiPost(_ api:String,contentType:String,postData:Data,complete:@escaping IPaURLResourceUISuccessHandler,failure:@escaping IPaURLResourceUIFailHandler) -> URLSessionUploadTask {
        return apiUpload(api, method: "POST", headerParam: ["content-type":contentType], data: postData, complete: complete, failure: failure)
    }
    @objc open func apiDelete(_ api:String,contentType:String,postData:Data,complete:@escaping IPaURLResourceUISuccessHandler,failure:@escaping IPaURLResourceUIFailHandler) -> URLSessionUploadTask {
        return apiUpload(api, method: "DELETE", headerParam: ["content-type":contentType], data: postData, complete: complete, failure: failure)
    }
    
    
    
    // MARK:NSURLSessionDelegate
    @objc open func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            IPaLog("\(error)")   
        }
    }
    @objc open func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
    }
    
    // MARK: helper method
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



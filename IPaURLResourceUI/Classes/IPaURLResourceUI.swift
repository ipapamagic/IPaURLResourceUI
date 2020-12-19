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
public typealias IPaURLResourceUIResult = Result<(URLResponse?,Any?),Error>
public typealias IPaURLResourceUIResultHandler = ((IPaURLResourceUIResult) ->())
open class IPaURLResourceUI : NSObject {
    public enum HttpMethod:String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }
    
    @objc open var baseURL:String! = ""
    @objc open var removeNSNull:Bool = true
    var responseHandler:IPaURLResponseHandler
    var operationQueue:OperationQueue = OperationQueue()
    @objc open lazy var urlSession:URLSession = {
        weak var weakSelf = self
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: weakSelf, delegateQueue: OperationQueue.main)
        return session
    }()
    public override init() {
        self.responseHandler = IPaURLJsonResponseHandler()
        super.init()
    }
    public init(_ responseHandler:IPaURLResponseHandler) {
        self.responseHandler = responseHandler
        super.init()
    }
    open func urlString(for api:String) -> String {
        return self.baseURL + api
    }
    open func urlString(for getApi:String!, params:[String:Any]?) -> String! {
        var apiURL = self.baseURL + getApi
        
        if let params = params {
            let paramStrings = params.map { (key,value) in
                return "\(key)=\(value)"
            }
            apiURL = apiURL + "?" + paramStrings.joined(separator: "&")
        }
        
        return ((apiURL as NSString).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed))!
    }
    
    open func apiData(with request:URLRequest,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataOperation {
        let operation = self.apiDataOperation(with: request, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    open func apiDataOperation(with request:URLRequest,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataOperation {
        
        let operation = IPaURLRequestDataOperation(urlSession: self.urlSession, request: request, complete: { (responseData,response,error) in
            let result = self.handleResponse(responseData, response: response, error: error)
            complete(result)
        })
        
        
        
        return operation
    }
    open func apiGet(_ api:String ,params:[String:Any]?,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataOperation {
        let operation = apiGetOperation(api, params: params, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    open func apiGetOperation(_ api:String ,params:[String:Any]?,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataOperation
    {
        let apiURL = urlString(for: api, params: params)
        var request = URLRequest(url: URL(string: apiURL!)!)
        request.httpMethod = HttpMethod.get.rawValue
        
        return apiDataOperation(with: request as URLRequest,complete:complete)
    }

    open func apiPost(_ api:String , params:[String:Any]?,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataOperation {
        let operation = self.apiPostOperation(api, params: params, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    open func apiPostOperation(_ api:String , params:[String:Any]?,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataOperation
    {
        return apiDataOperation(api,method:HttpMethod.post,params:params,complete:complete)
    }
    open func apiPut(_ api:String, params:[String:Any]?,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataOperation {
        let operation = apiPutOperation(api, params: params, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    open func apiPutOperation(_ api:String, params:[String:Any]?,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataOperation {
        
        return apiDataOperation(api ,method:HttpMethod.put, params:params,complete:complete)
    }
    
    
    open func apiData(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,params:[String:Any]?,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataOperation {
        let operation = apiDataOperation(api, method: method, headerFields:headerFields, params:params, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    open func apiDataOperation(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,params:[String:Any]?,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataOperation

    {
        var apiURL:String
        var request:URLRequest
        if method == .get {
            apiURL = urlString(for: api, params: params)
            request = URLRequest(url: URL(string: apiURL)!)
        }
        else {
            apiURL = urlString(for: api)
            request = URLRequest(url: URL(string: apiURL)!)
            if let params = params {
                let characterSet = CharacterSet(charactersIn: "!*'();@&+$,/?%#[]~=_-.:").inverted
                
                let valuePairs:[String] = params.map { (key,value) in
                    let value = "\(value)".addingPercentEncoding(withAllowedCharacters: characterSet) ?? ""
                    return "\(key)=\(value)"
                }
                let postString = valuePairs.joined(separator: "&")
                request.httpBody = postString.data(using: String.Encoding.utf8, allowLossyConversion: false)
            }
        }
        
        
        
        request.httpMethod = method.rawValue
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        if let fields = headerFields {
            for (key,value) in fields {
                request.setValue(value,forHTTPHeaderField: key)
            }
        }
        return apiDataOperation(with: request,complete:complete)
    }
    open func apiUpload(_ api:String,method:HttpMethod,headerFields:[String:String]?,json:Any,complete:@escaping IPaURLResourceUIResultHandler) throws -> IPaURLRequestOperation {
        let operation = try apiUploadOperation(api, method: method,headerFields:headerFields, json: json, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    open func apiUploadOperation(_ api:String,method:HttpMethod,headerFields:[String:String]?,json:Any,complete:@escaping IPaURLResourceUIResultHandler) throws -> IPaURLRequestOperation {

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0))
            var header = headerFields ?? [String:String]()
            header["Content-Type"] = "application/json"
            return apiUploadOperation(api, method: method, headerFields: header, data: jsonData, complete: complete)
            
        }
        catch let error as NSError {
            throw error
        }
        
    }
    func apiUpload(_ api:String,method:HttpMethod,headerFields:[String:String]?,file:Any,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        let operation = self.apiUploadOperation(api, method: method, headerFields: headerFields,file:file, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    func apiUploadOperation(_ api:String,method:HttpMethod,headerFields:[String:String]?,file:Any,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        let apiURL = urlString(for: api)
        var request = URLRequest(url:URL(string: apiURL)!)
        request.httpMethod = method.rawValue
        if let headerFields = headerFields {
            for (key,value) in headerFields {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        let operation = IPaURLRequestUploadOperation(urlSession: self.urlSession, request: request, file: file, complete: {
            (responseData,response,error)  in
            let result = self.handleResponse(responseData, response: response, error: error)
            complete(result)
        })
        
        return operation
    }
    open func apiUpload(_ api:String,method:HttpMethod,headerFields:[String:String]?,fileUrl:URL,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        let operation = apiUploadOperation(api, method: method,headerFields: headerFields,fileUrl: fileUrl,complete:complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    open func apiUploadOperation(_ api:String,method:HttpMethod,headerFields:[String:String]?,fileUrl:URL,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        return self.apiUploadOperation(api, method: method, headerFields: headerFields, file:fileUrl ,complete: complete)
    }
    open func apiUpload(_ api:String,method:HttpMethod,headerFields:[String:String]?,data:Data,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        let operation = apiUploadOperation(api, method: method, headerFields: headerFields, data: data, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    
    open func apiUploadOperation(_ api:String,method:HttpMethod,headerFields:[String:String]?,data:Data,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        return self.apiUploadOperation(api, method: method, headerFields: headerFields,file:data, complete: complete)
    }
    open func apiUpload(_ api:String,method:HttpMethod,headerFields:[String:String]?,params:[String:Any],file:IPaMultipartFile,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        let operation = self.apiUploadOperation(api, method: method, headerFields: headerFields, params:params, file:file, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    open func apiUploadOperation(_ api:String,method:HttpMethod,headerFields:[String:String]?,params:[String:Any],file:IPaMultipartFile,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        return self.apiUploadOperation(api, method: method, headerFields: headerFields, params: params, files: [file], complete: complete)
    }
    open func apiUpload(_ api:String,method:HttpMethod,headerFields:[String:String]?,params:[String:Any],files:[IPaMultipartFile],complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        let extractedExpr = apiUploadOperation(api, method: method,headerFields: headerFields, params:params, files: files, complete: complete)
        let operation = extractedExpr
        self.operationQueue.addOperation(operation)
        return operation
    }
    open func apiUploadOperation(_ api:String,method:HttpMethod,headerFields:[String:String]?,params:[String:Any],files:[IPaMultipartFile],complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        
        let tempFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("IPaURLResponseUITemp\(UUID().uuidString)")
        let boundary:String = ProcessInfo.processInfo.globallyUniqueString
        let contentType = "multipart/form-data; boundary=\(boundary)"
        let outputStream = OutputStream(toFileAtPath: tempFilePath, append: false)!
//        outputStream.schedule(in: RunLoop.main, forMode:.default)
        outputStream.open()
        var dataString = ""
        for (key,value) in params {
            dataString += "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n"
        }
        if let data = dataString.data(using: .utf8, allowLossyConversion: false) {
            _ = data.withUnsafeBytes {
                outputStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
                
            }
        }
        for file in files {
            file.write(outputStream, boundary: boundary)
        }
        let endOfDataString = "--\(boundary)--\r\n"
        if let data = endOfDataString.data(using: .utf8, allowLossyConversion: false)  {
            _ = data.withUnsafeBytes {
                outputStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
            }
        }
        
        
        outputStream.close()
        
        
        
        let fileUrl = URL(fileURLWithPath: tempFilePath)
//        let data = try! Data(contentsOf: fileUrl)
//        let content = String(data: data, encoding: .utf8)
        let fileInfo =  try? FileManager.default.attributesOfItem(atPath: tempFilePath)
        let fileSize = "\(fileInfo?[FileAttributeKey.size] ?? 0)"
        var header = ["Content-Type":contentType,"Content-Length":fileSize]
        if let headerFields = headerFields {
            for (key,value) in headerFields {
                header[key] = value
            }
        }
        let operation = apiUploadOperation(api, method: method, headerFields:header, fileUrl: fileUrl) { (result) in
            
            complete(result)
            
            try? FileManager.default.removeItem(atPath: tempFilePath)
            
        }
        return operation
    }
    open func apiPut(_ api:String,contentType:String,postData:Data,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        let operation = apiPutOperation(api, contentType: contentType,postData: postData,complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    open func apiPutOperation(_ api:String,contentType:String,postData:Data,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        return apiUploadOperation(api, method: HttpMethod.put, headerFields: ["Content-Type":contentType], data: postData, complete: complete)
    }
    open func apiPost(_ api:String,contentType:String,postData:Data,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        let operation = apiPostOperation(api, contentType: contentType,postData:postData,complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    open func apiPostOperation(_ api:String,contentType:String,postData:Data,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        return apiUploadOperation(api, method: HttpMethod.post, headerFields: ["Content-Type":contentType], data: postData, complete: complete)
    }
    open func apiDelete(_ api:String,contentType:String,postData:Data,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        let operation = self.apiDeleteOperation(api, contentType: contentType, postData: postData, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    open func apiDeleteOperation(_ api:String,contentType:String,postData:Data,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadOperation {
        return apiUploadOperation(api, method: HttpMethod.delete, headerFields: ["Content-Type":contentType], data: postData, complete: complete)
    }
    func handleResponse(_ responseData:Data?,response:URLResponse?,error:Error?) -> Result<(URLResponse?,Any?),Error> {
        if let error = error {
            return .failure(error)
            
        }
        guard let response = response else {
            let error = NSError(domain: "com.IPaURLResponseUI", code: 3000, userInfo: [NSLocalizedDescriptionKey:"there is no response !!"])
            return .failure(error)
        }
        guard let responseData = responseData,responseData.count > 0 else {
            let error = NSError(domain: "com.IPaURLResponseUI", code: 3001, userInfo: [NSLocalizedDescriptionKey:"there is no response for \(response.url?.absoluteString ?? "(unknown url)")"])
            return .failure(error)
            
        }
        let decodeData:Any? = self.responseHandler.handleResponse(responseData, response: response)

        return .success((response,decodeData))
    }
}

extension IPaURLResourceUI :URLSessionDelegate
{
    // MARK:URLSessionDelegate
    open func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            IPaLog("\(error)")
        }
    }
    open func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
    }
    

}


extension IPaURLResourceUI {
    public static func resultHandler<T>(_ result:IPaURLResourceUIResult) -> T? {
        switch result {
        case .success(let (_,data)):
            return data as? T
        case .failure(_):
            return nil
        }
    }
}

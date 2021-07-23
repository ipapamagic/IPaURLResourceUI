//
//  IPaURLResourceUI.swift
//  IPaURLResourceUI
//
//  Created by IPa Chen on 2015/6/12.
//  Copyright (c) 2015年 IPaPa. All rights reserved.
//

import Foundation
import IPaLog
import Combine
public typealias IPaURLResourceUIResult = Result<(URLResponse?,Data),Error>
public typealias IPaURLResourceUIResultHandler = ((IPaURLResourceUIResult) ->())
public protocol IPaURLResourceUIDelegate {
    func sharedHeader(for resourceUI:IPaURLResourceUI) -> [String:String]
    func handleChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    func handleResponse(_ response:HTTPURLResponse,responseData:Data?) -> Error?
}
public class IPaURLResourceUI : NSObject {
    public enum HttpMethod:String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }
    
    public var baseUrl:URL!
    public var delegate:IPaURLResourceUIDelegate?
    var sharedHeader:[String:String] {
        delegate?.sharedHeader(for: self) ?? [String:String]()
    }
    public var removeNSNull:Bool = true
    var operationQueue:OperationQueue = OperationQueue()
    public lazy var urlSession:URLSession = {
        weak var weakSelf = self
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: weakSelf, delegateQueue: OperationQueue.main)
        return session
    }()
    
    public init(with baseUrl:URL,delegate:IPaURLResourceUIDelegate? = nil) {
        super.init()
        self.baseUrl = baseUrl
        self.delegate = delegate
    }

    func generateURLRequest(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,params:[String:Any]? = nil) -> URLRequest {
        var apiURL:URL = self.baseUrl.appendingPathComponent(api)
        var request:URLRequest
        if method == .get {
            var apiURLComponent = URLComponents(url: apiURL, resolvingAgainstBaseURL: true)!
            
            if let params = params {
                apiURLComponent.queryItems = params.map { (key,value) in
                    return URLQueryItem(name: key, value: "\(value)")
                }
                
            }
            request = URLRequest(url: apiURLComponent.url!)
        }
        else {
            
            request = URLRequest(url: apiURL)
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
        
        for (key,value) in sharedHeader {
            request.setValue(value,forHTTPHeaderField: key)
        }
    
        
        if let fields = headerFields {
            for (key,value) in fields {
                request.setValue(value,forHTTPHeaderField: key)
            }
        }
        return request
    }
    @discardableResult
    public func apiData(with request:URLRequest,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataTaskOperation {
        let operation = self.apiDataOperation(with: request, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    public func apiDataOperation(with request:URLRequest,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataTaskOperation {
        
        let operation = IPaURLRequestDataTaskOperation(urlSession: self.urlSession, request: request, complete: { (responseData,response,error) in
            let result = self.handleResponse(responseData, response: response, error: error)
            complete(result)
        })
        return operation
    }
    
    @discardableResult
    public func apiData(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,params:[String:Any]? = nil,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestDataTaskOperation {
        let request = self.generateURLRequest(api, method: method, headerFields: headerFields, params: params)
        return self.apiData(with: request, complete: complete)
    }
    @discardableResult
    public func apiUpload(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,json:Any,complete:@escaping IPaURLResourceUIResultHandler) throws -> IPaURLRequestTaskOperation {
        
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0))
        var header = headerFields ?? [String:String]()
        header["Content-Type"] = "application/json"
        
        let operation = apiUploadOperation(api, method: method, headerFields: header, file: jsonData, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    
    func apiUploadOperation(_ api:String,method:HttpMethod,headerFields:[String:String]?,file:Any,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadTaskOperation {
        let request = self.generateURLRequest(api, method: method, headerFields: headerFields)
        let operation = IPaURLRequestUploadTaskOperation(urlSession: self.urlSession, request: request, file: file, complete: {
            (responseData,response,error)  in
            let result = self.handleResponse(responseData, response: response, error: error)
            complete(result)
        })
        
        return operation
    }
    @discardableResult
    public func apiUpload(_ api:String,method:HttpMethod,headerFields:[String:String]?,fileUrl:URL,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadTaskOperation {
        let operation = apiUploadOperation(api, method: method,headerFields: headerFields,file: fileUrl,complete:complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    @discardableResult
    public func apiUpload(_ api:String,method:HttpMethod,headerFields:[String:String]?,data:Data,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestUploadTaskOperation {
        let operation = apiUploadOperation(api, method: method, headerFields: headerFields, file: data, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    
    @discardableResult
    public func apiFormDataUpload(_ api:String,method:HttpMethod,headerFields:[String:String]?,params:[String:Any],file:IPaMultipartFile,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestFormDataUploadTaskOperation {
        let operation = self.apiFormDataUploadOperation(api, method: method, headerFields: headerFields, params:params, file:file, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    public func apiFormDataUploadOperation(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,params:[String:Any]? = nil,file:IPaMultipartFile,complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestFormDataUploadTaskOperation {
        return self.apiFormDataUploadOperation(api, method: method, headerFields: headerFields, params: params, files: [file], complete: complete)
    }
    @discardableResult
    public func apiFormDataUpload(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,params:[String:Any]? = nil,files:[IPaMultipartFile],complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestFormDataUploadTaskOperation {
        let extractedExpr = apiFormDataUploadOperation(api, method: method,headerFields: headerFields, params:params, files: files, complete: complete)
        let operation = extractedExpr
        self.operationQueue.addOperation(operation)
        return operation
    }
    public func apiFormDataUploadOperation(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,params:[String:Any]? = nil,files:[IPaMultipartFile],complete:@escaping IPaURLResourceUIResultHandler) -> IPaURLRequestFormDataUploadTaskOperation {
        
        let request = self.generateURLRequest(api, method: method, headerFields: headerFields)
        return IPaURLRequestFormDataUploadTaskOperation(urlSession: self.urlSession, request: request, files: files, complete: {
            (responseData,response,error)  in
            let result = self.handleResponse(responseData, response: response, error: error)
            complete(result)
        })
    }
    
    func handleResponse(_ responseData:Data?,response:URLResponse?,error:Error?) -> IPaURLResourceUIResult {
        if let error = error {
            return .failure(error)
        }
        else if let httpResponse:HTTPURLResponse = response as? HTTPURLResponse, let error = self.delegate?.handleResponse(httpResponse, responseData: responseData) {
            return .failure(error)
        }
        return .success((response,responseData ?? Data()))
    }
}

extension IPaURLResourceUI :URLSessionDelegate
{
    // MARK:URLSessionDelegate
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            IPaLog("\(error)")
        }
    }
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
       
        
        self.delegate?.handleChallenge(challenge, completionHandler: completionHandler)
    }
}


//MARK : Combine api
@available(iOS 13.0, *)
extension IPaURLResourceUI {
    public func apiDataTaskPublisher(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,params:[String:Any]? = nil) -> URLSession.DataTaskPublisher {
        let request = self.generateURLRequest(api, method: method, headerFields: headerFields, params: params)
        return self.urlSession.dataTaskPublisher(for: request)
    }
    public func apiDataTaskPublisher(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,json:Any) -> URLSession.DataTaskPublisher {
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0))
        return self.apiDataTaskPublisher(api, method: method,headerFields: headerFields,httpBody: jsonData)
    }
    public func apiDataTaskPublisher(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,httpBody:Data) -> URLSession.DataTaskPublisher {
        var request = self.generateURLRequest(api, method: method, headerFields: headerFields)
        request.httpBody = httpBody
        return self.urlSession.dataTaskPublisher(for: request)
    }
    public func apiDataTaskPublisher(_ request:URLRequest) -> URLSession.DataTaskPublisher {
        return self.urlSession.dataTaskPublisher(for: request)
    }
    @discardableResult
    public func apiData<T>(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,params:[String:Any]? = nil,handle:@escaping ((URLSession.DataTaskPublisher)-> AnyPublisher<T, Error>),receiveValue:((T)->())? = nil,complete:((Subscribers.Completion<Error>)->())? = nil ) -> IPaURLRequestPublisherOperation<T> {
        let request = self.generateURLRequest(api, method: method, headerFields: headerFields, params: params)
        let operation = self.apiDataOperation(with:request, handle: handle, receiveValue: receiveValue, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    
    @discardableResult
    public func apiData<T>(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,json:Any,handle:@escaping ((URLSession.DataTaskPublisher)-> AnyPublisher<T, Error>),receiveValue:((T)->())? = nil,complete:((Subscribers.Completion<Error>)->())? = nil) -> IPaURLRequestPublisherOperation<T> {
        
        var header = headerFields ?? [String:String]()
        header["Content-Type"] = "application/json"
        var request = self.generateURLRequest(api, method: method, headerFields: header, params: nil)
        request.httpBody = try? JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0))
        
        let operation = self.apiDataOperation(with:request, handle: handle, receiveValue: receiveValue, complete: complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    public func apiDataOperation<T>(with request:URLRequest,handle:@escaping ((URLSession.DataTaskPublisher)-> AnyPublisher<T, Error>),receiveValue:((T)->())?,complete:((Subscribers.Completion<Error>)->())? ) -> IPaURLRequestPublisherOperation<T> {
        return IPaURLRequestPublisherOperation(urlSession: urlSession, request: request, handle: handle, receiveValue: receiveValue, complete: complete)
        
    }
    @discardableResult
    public func apiFormData<T>(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,params:[String:Any]? = nil,files:[IPaMultipartFile],handle:@escaping ((URLSession.DataTaskPublisher)-> AnyPublisher<T, Error>),receiveValue:((T)->())?,complete:((Subscribers.Completion<Error>)->())? ) -> IPaURLRequestFormDataPublisherOperation<T> {
        let request = self.generateURLRequest(api, method: method, headerFields: headerFields, params: params)
        let operation = self.apiFormDataOperation( with: request,params:params,files:files,handle:handle,receiveValue:receiveValue,complete:complete)
        self.operationQueue.addOperation(operation)
        return operation
    }
    public func apiFormDataTaskPublisher(_ api:String,method:HttpMethod,headerFields:[String:String]? = nil,params:[String:Any]? = nil,files:[IPaMultipartFile]) -> URLSession.DataTaskPublisher {
        var request = self.generateURLRequest(api, method: method, headerFields: headerFields)
        request.writeFormData(params ?? [String:Any](), files: files)
//        request.httpBody = httpBody
        return self.urlSession.dataTaskPublisher(for: request)
    }
    public func apiFormDataOperation<T>(with request:URLRequest,params:[String:Any]? = nil,files:[IPaMultipartFile],handle:@escaping ((URLSession.DataTaskPublisher)-> AnyPublisher<T, Error>),receiveValue:((T)->())?,complete:((Subscribers.Completion<Error>)->())? ) -> IPaURLRequestFormDataPublisherOperation<T> {
        return IPaURLRequestFormDataPublisherOperation(urlSession: urlSession, request: request,params:params ?? [String:Any](),files:files, handle: handle, receiveValue: receiveValue, complete: complete)
        
    }
    
}

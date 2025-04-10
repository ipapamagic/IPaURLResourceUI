//
//  IPaURLRequestOperation.swift
//  IPaURLResourceUI
//
//  Created by IPa Chen on 2020/7/20.
//

import Foundation
import IPaLog
import Combine
public typealias IPaURLRequestOperationCompletion =  (@Sendable (Data?,URLResponse?,Error?)->())
@objc public class IPaURLRequestTaskOperation: Operation ,@unchecked Sendable {
    var urlSession:URLSession
    var _request:URLRequest
    public var request:URLRequest {
        return _request
    }
    @objc dynamic public private(set) var task:URLSessionTask?
    @objc dynamic public var progress:Double {
        return self.task?.progress.fractionCompleted ?? 0
    }
    var requestCompleteBlock: IPaURLRequestOperationCompletion?
    init(urlSession:URLSession,request:URLRequest,complete:@escaping IPaURLRequestOperationCompletion) {
        self.urlSession = urlSession
        self._request = request
        self.requestCompleteBlock = complete
    }
    @objc class public func keyPathsForValuesAffectingProgress() -> Set<String> {
       return Set(arrayLiteral: "task","task.progress.fractionCompleted")
    }
    
    override public var isExecuting:Bool {
        get {
            return task?.state == URLSessionTask.State.running
        }
    }
    @objc override public var isFinished:Bool {
        get {
            let isFinished = (task?.state == URLSessionTask.State.completed) && (self.requestCompleteBlock == nil)
            return isFinished
        }
    }
    override public var isConcurrent:Bool {
        get {
            return true
        }
    }
    override public var isCancelled: Bool {
        get {
            return task?.state == URLSessionTask.State.canceling
        }
    }
    override public func start() {
        self.willChangeValue(forKey: "isExecuting")
        self.executeOperation()
        self.didChangeValue(forKey: "isExecuting")
    }
    func executeOperation() {
        self.startURLConnection()
    }
    func startURLConnection() {
        let task = self.createTask { (responseData, response, error) in
            
            self.requestCompleteBlock?(responseData, response, error)
            self.willChangeValue(forKey: "isFinished")
            self.requestCompleteBlock = nil
            self.didChangeValue(forKey: "isFinished")
            
        }
        self.task = task
        task.resume()
    }
    override public func cancel() {
        self.task?.cancel()
    }
    func createTask(_ complete:@escaping @Sendable (Data?,URLResponse?,Error?)->()) -> URLSessionTask {
        fatalError("do not use IPaURLRequestOperation directly!")
    }
   
}
public class IPaURLRequestDataTaskOperation :IPaURLRequestTaskOperation,@unchecked Sendable {
    public override func createTask(_ complete:@escaping @Sendable IPaURLRequestOperationCompletion) -> URLSessionTask {
        
        urlSession.dataTask(with: request, completionHandler: complete)
        
    }
}
public class IPaURLRequestFormDataUploadTaskOperation:IPaURLRequestTaskOperation, IPaURLFormDataStreamWriter ,@unchecked Sendable  {
    var outputStream: OutputStream?
    var params:[String:Any]
    var files:[IPaMultipartFile]
    lazy var tempFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("IPaURLResponseUITemp\(UUID().uuidString)")
    init(urlSession: URLSession, request: URLRequest, params:[String:Any] = [String:Any](),files:[IPaMultipartFile], complete: @escaping IPaURLRequestOperationCompletion) {
        self.params = params
        self.files = files
        super.init(urlSession: urlSession, request: request, complete: complete)
        
    }
    override func executeOperation() {
        self.createOutputStream()
    }
    public override func createTask(_ complete: @escaping @Sendable(Data?, URLResponse?, Error?) -> ()) -> URLSessionTask {
        
        let fileUrl = URL(fileURLWithPath: self.tempFilePath)
        return self.urlSession.uploadTask(with: request, fromFile: fileUrl) { data, response, error in
            try? FileManager.default.removeItem(atPath: self.tempFilePath)
            complete(data,response,error)
        }
        
            
    }
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        self.streamDelegateFunction(aStream,handle: eventCode)
    }
    
}
public class IPaURLRequestUploadFileTaskOperation:IPaURLRequestTaskOperation,@unchecked Sendable  {
    var fileUrl:URL
    init(urlSession: URLSession, request: URLRequest, fileUrl:URL, complete: @escaping IPaURLRequestOperationCompletion) {
        self.fileUrl = fileUrl
        super.init(urlSession: urlSession, request: request, complete: complete)
        
    }
    public override func createTask(_ complete: @escaping @Sendable(Data?, URLResponse?, Error?) -> ()) -> URLSessionTask {
        return self.urlSession.uploadTask(with: self._request, fromFile: fileUrl,completionHandler: complete)
    }
}
public class IPaURLRequestUploadDataTaskOperation:IPaURLRequestTaskOperation,@unchecked Sendable  {
    var data:Data
    init(urlSession: URLSession, request: URLRequest, data:Data, complete: @escaping IPaURLRequestOperationCompletion) {
        self.data = data
        super.init(urlSession: urlSession, request: request, complete: complete)
        
    }
    public override func createTask(_ complete: @escaping @Sendable(Data?, URLResponse?, Error?) -> ()) -> URLSessionTask {
        return self.urlSession.uploadTask(with: self._request, from: data, completionHandler: complete)
    }
}
@available(iOS 13.0, *)
public class IPaURLRequestPublisherOperation<T>:Operation,@unchecked Sendable  {
    var urlSession:URLSession
    var _request:URLRequest
    var anyCancellable:AnyCancellable? = nil
    var publisherHandler:(URLSession.DataTaskPublisher)-> AnyPublisher<T, Error>
    var receiveValueHandler:((T)->())?
    var completeHandler:((Subscribers.Completion<Error>)->())?
    var _isFinished = false
    public var request:URLRequest {
        return _request
    }
    init(urlSession:URLSession,request:URLRequest,handle: @escaping ((URLSession.DataTaskPublisher)-> AnyPublisher<T, Error>),receiveValue: ((T)->())?,complete:((Subscribers.Completion<Error>)->())? ) {
        self.urlSession = urlSession
        self._request = request
        self.publisherHandler = handle
        self.receiveValueHandler = receiveValue
        self.completeHandler = complete
    }
    override public var isExecuting:Bool {
        get {
            return anyCancellable != nil
        }
    }
    override public var isConcurrent:Bool {
        get {
            return true
        }
    }
    override public var isFinished: Bool {
        get {
            return _isFinished
        }
    }
    override public func start() {
        self.willChangeValue(forKey: "isExecuting")
        self.executeOperation()
        self.didChangeValue(forKey: "isExecuting")
    }
    func executeOperation() {
        self.startURLConnection()
    }
    func startURLConnection() {
        let dataPublisher = self.urlSession.dataTaskPublisher(for: request)
        let publisher:AnyPublisher<T, Error> = self.publisherHandler(dataPublisher)
        self.anyCancellable = publisher.sink(receiveCompletion: {
            result in
            self.willChangeValue(forKey: "isFinished")
            self.anyCancellable = nil
            
            self.completeHandler?(result)
            self._isFinished = true
            self.didChangeValue(forKey: "isFinished")
        }, receiveValue: {
            value in
            self.receiveValueHandler?(value)
        })
    }
    override public func cancel() {
        self.anyCancellable?.cancel()
    }
}
@available(iOS 13.0, *)
public class IPaURLRequestFormDataPublisherOperation<T>:IPaURLRequestPublisherOperation<T>,IPaURLFormDataStreamWriter,@unchecked Sendable  {
    var outputStream:OutputStream?
    var files:[IPaMultipartFile]
    lazy var tempFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("IPaURLResponseUITemp\(UUID().uuidString)")
    var params: [String : Any]
    init(urlSession: URLSession, request: URLRequest, params:[String:Any] = [String:Any](),files:[IPaMultipartFile],handle: @escaping ((URLSession.DataTaskPublisher)-> AnyPublisher<T, Error>),receiveValue: ((T)->())?,complete:((Subscribers.Completion<Error>)->())? ) {
        self.params = params
        self.files = files
        super.init(urlSession: urlSession, request: request,handle: handle,receiveValue: receiveValue,complete: complete)
        
    }
    override func executeOperation() {
        self.createOutputStream()
    }
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        self.streamDelegateFunction(aStream,handle: eventCode)
    }
}

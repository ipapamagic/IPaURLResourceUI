//
//  IPaURLRequestOperation.swift
//  IPaURLResourceUI
//
//  Created by IPa Chen on 2020/7/20.
//

import Foundation
import IPaLog
import IPaNetworkState
import Combine
public typealias IPaURLRequestOperationCompletion = ((Data?,URLResponse?,Error?)->())
public class IPaURLRequestTaskOperation: Operation {
    var urlSession:URLSession
    var _request:URLRequest
    var _task:URLSessionTask?
    @objc dynamic public var progress:Float = 0
    var progressObserver:NSKeyValueObservation?
    public var request:URLRequest {
        return _request
    }
    @objc public var task:URLSessionTask? {
        return _task
    }
    var requestCompleteBlock: IPaURLRequestOperationCompletion?
    init(urlSession:URLSession,request:URLRequest,complete:@escaping IPaURLRequestOperationCompletion) {
        self.urlSession = urlSession
        self._request = request
        self.requestCompleteBlock = complete
    }
    override public var isExecuting:Bool {
        get {
            guard let task = _task else {
                return false
            }
            return task.state == URLSessionTask.State.running
        }
    }
    override public var isFinished:Bool {
        get {
            guard let task = _task else {
                return false
            }
            let isFinished = (task.state == URLSessionTask.State.completed) && (self.requestCompleteBlock == nil)
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
            guard let task = _task else {
                return false
            }
            return task.state == URLSessionTask.State.canceling
        }
    }
    override public func start() {
        IPaNetworkState.startNetworking()
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
            IPaNetworkState.endNetworking()
            self.progressObserver?.invalidate()
            self.progressObserver = nil
        }
        self._task = task
        
        self.progressObserver = task.observe(\.countOfBytesSent) { (task, value) in
            self.progress = Float(task.countOfBytesSent) / Float(task.countOfBytesExpectedToSend)
        }
        
        
        task.resume()
    }
    override public func cancel() {
        self._task?.cancel()
    }
    func createTask(_ complete:@escaping (Data?,URLResponse?,Error?)->()) -> URLSessionTask {
        fatalError("do not use IPaURLRequestOperation directly!")
    }
    
}
public class IPaURLRequestDataTaskOperation :IPaURLRequestTaskOperation {
    public override func createTask(_ complete:@escaping IPaURLRequestOperationCompletion) -> URLSessionTask {
        
        urlSession.dataTask(with: request, completionHandler: complete)
        
    }
}
public class IPaURLRequestFormDataUploadTaskOperation:IPaURLRequestTaskOperation, StreamDelegate {
    var params:[String:Any]
    var files:[IPaMultipartFile]
    lazy var tempFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("IPaURLResponseUITemp\(UUID().uuidString)")
    init(urlSession: URLSession, request: URLRequest, params:[String:Any] = [String:Any](),files:[IPaMultipartFile], complete: @escaping IPaURLRequestOperationCompletion) {
        self.params = params
        self.files = files
        super.init(urlSession: urlSession, request: request, complete: complete)
        
    }
    override func executeOperation() {
        let outputStream = OutputStream(toFileAtPath: tempFilePath, append: false)!
        outputStream.delegate = self
        
        outputStream.schedule(in: RunLoop.main, forMode:.default)
        
        outputStream.open()
    }
    public override func createTask(_ complete: @escaping (Data?, URLResponse?, Error?) -> ()) -> URLSessionTask {
        
        let fileUrl = URL(fileURLWithPath: self.tempFilePath)
        return self.urlSession.uploadTask(with: request, fromFile: fileUrl) { data, response, error in
            try? FileManager.default.removeItem(atPath: self.tempFilePath)
            complete(data,response,error)
        }
        
            
    }
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard let outputStream = aStream as? OutputStream else {
            return
        }
        switch eventCode {
        case .errorOccurred:
            if let errorString = aStream.streamError?.localizedDescription {
                IPaLog(errorString)
            }
//        case .openCompleted:
//            IPaLog("Stream open completed")
        case .hasSpaceAvailable:
            let boundary:String = ProcessInfo.processInfo.globallyUniqueString
            let contentType = "multipart/form-data; boundary=\(boundary)"
            var dataString = ""
            for (key,value) in params {
                dataString += "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n"
            }
            if dataString.count > 0, let data = dataString.data(using: .utf8, allowLossyConversion: false) {
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
            
    //        let data = try! Data(contentsOf: fileUrl)
    //        let content = String(data: data, encoding: .utf8)
            let fileInfo =  try? FileManager.default.attributesOfItem(atPath: tempFilePath)
            let fileSize = "\(fileInfo?[FileAttributeKey.size] ?? 0)"
            let header = ["Content-Type":contentType,"Content-Length":fileSize]
            
            for (key,value) in header {
                self._request.setValue(value, forHTTPHeaderField: key)
            }
            self.startURLConnection()
        case .endEncountered:
            
            
            if let _ = aStream.property(forKey: .dataWrittenToMemoryStreamKey) {
                IPaLog("No data written to memory!");
            }
            aStream.close()
            aStream.remove(from: RunLoop.current, forMode: .default)
            
            break;
        default:
            break
        }
    }
}
public class IPaURLRequestUploadTaskOperation:IPaURLRequestTaskOperation {
    var file:Any
    init(urlSession: URLSession, request: URLRequest, file:Any, complete: @escaping IPaURLRequestOperationCompletion) {
        self.file = file
        super.init(urlSession: urlSession, request: request, complete: complete)
        
    }
    public override func createTask(_ complete: @escaping (Data?, URLResponse?, Error?) -> ()) -> URLSessionTask {
        switch file {
        case let fileUrl as URL:
            return self.urlSession.uploadTask(with: self._request, fromFile: fileUrl,completionHandler: complete)
        case let fileData as Data:
            return self.urlSession.uploadTask(with: self._request, from: fileData, completionHandler: complete)
        default:
            break
        }
        fatalError("IPaURLRequestUploadOperation: unknow file type!")
    }
}
@available(iOS 13.0, *)
public class IPaURLRequestPublisherOperation<T>:Operation {
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
        IPaNetworkState.startNetworking()
        self.willChangeValue(forKey: "isExecuting")
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
        
        
        self.didChangeValue(forKey: "isExecuting")
    }
    override public func cancel() {
        self.anyCancellable?.cancel()
    }
}

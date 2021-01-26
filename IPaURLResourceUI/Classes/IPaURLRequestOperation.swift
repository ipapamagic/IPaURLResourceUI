//
//  IPaURLRequestOperation.swift
//  IPaURLResourceUI
//
//  Created by IPa Chen on 2020/7/20.
//

import Foundation
import IPaLog
import IPaNetworkState
public typealias IPaURLRequestOperationCompletion = ((Data?,URLResponse?,Error?)->())
open class IPaURLRequestOperation: Operation {
    var urlSession:URLSession
    var _request:URLRequest
    var _task:URLSessionTask?
    @objc dynamic open var progress:Float = 0
    var progressObserver:NSKeyValueObservation?
    open var request:URLRequest {
        return _request
    }
    @objc open var task:URLSessionTask? {
        return _task
    }
    var requestCompleteBlock: IPaURLRequestOperationCompletion?
    init(urlSession:URLSession,request:URLRequest,complete:@escaping IPaURLRequestOperationCompletion) {
        self.urlSession = urlSession
        self._request = request
        self.requestCompleteBlock = complete
    }
    override open var isExecuting:Bool {
        get {
            guard let task = _task else {
                return false
            }
            return task.state == URLSessionTask.State.running
        }
    }
    override open var isFinished:Bool {
        get {
            guard let task = _task else {
                return false
            }
            let isFinished = (task.state == URLSessionTask.State.completed) && (self.requestCompleteBlock == nil)
            return isFinished
        }
    }
    override open var isConcurrent:Bool {
        get {
            return true
        }
    }
    override open var isCancelled: Bool {
        get {
            guard let task = _task else {
                return false
            }
            return task.state == URLSessionTask.State.canceling
        }
    }
    override open func start() {
        IPaNetworkState.startNetworking()
        self.willChangeValue(forKey: "isExecuting")
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
        
        
        self._task?.resume()
        self.didChangeValue(forKey: "isExecuting")
    }
    override open func cancel() {
        self._task?.cancel()
    }
    func createTask(_ complete:@escaping (Data?,URLResponse?,Error?)->()) -> URLSessionTask {
        fatalError("do not use IPaURLRequestOperation directly!")
    }
    
}
open class IPaURLRequestDataOperation :IPaURLRequestOperation {
    open override func createTask(_ complete:@escaping (Data?,URLResponse?,Error?)->()) -> URLSessionTask {
        
        urlSession.dataTask(with: request, completionHandler: complete)
        
    }
}
open class IPaURLRequestUploadOperation:IPaURLRequestOperation {
    var file:Any
    init(urlSession: URLSession, request: URLRequest, file:Any, complete: @escaping IPaURLRequestOperationCompletion) {
        self.file = file
        super.init(urlSession: urlSession, request: request, complete: complete)
        
    }
    open override func createTask(_ complete: @escaping (Data?, URLResponse?, Error?) -> ()) -> URLSessionTask {
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

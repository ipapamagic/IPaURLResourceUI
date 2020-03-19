//
//  IPaServerAPI.swift
//  IPaURLResourceUI
//
//  Created by IPa Chen on 2015/6/14.
//  Copyright (c) 2015年 IPaPa. All rights reserved.
//

import Foundation

public class IPaServerAPI :NSObject {
    let resourceUI:IPaURLResourceUI
    var currentAPITask:URLSessionDataTask?
    public init(resourceUI:IPaURLResourceUI) {
        self.resourceUI = resourceUI
    }

    public func apiPerform(_ api:String,method:String,param:[String:Any]?,complete:@escaping IPaURLResourceUIResultHandler) {
        
        if let task = currentAPITask {
            if task.state == .running {
                task.cancel()
            }
        }

        let aMethod = method.uppercased()
        if aMethod == "GET" {
            currentAPITask = resourceUI.apiGet(api, param:param, complete:{
                result in
                self.currentAPITask = nil
                switch (result) {
                case .success(let (response,responseObject)):
                    complete(.success((response,responseObject)))
                case .failure(let error):
                    complete(.failure(error))
                }
            })
        }
        else if aMethod == "POST" {
            currentAPITask = resourceUI.apiPost(api, param:param,  complete:{
                result in
                self.currentAPITask = nil
                switch (result) {
                case .success(let (response,responseObject)):
                    complete(.success((response,responseObject)))
                case .failure(let error):
                    complete(.failure(error))
                }
            })
        }

    }
    public func apiPut(_ api:String, json:Any,complete:@escaping IPaURLResourceUIResultHandler) {

        var jsonError:NSError?
        var jsonData:Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions())
        } catch let error as NSError {
            jsonError = error
            jsonData = nil
        }
        
        if let error = jsonError {
            complete(.failure(error))
            return
        }
        if let task = currentAPITask {
            if task.state == .running {
                task.cancel()
            }
        }
        
        currentAPITask = resourceUI.apiPut(api, contentType: "application/json", postData: jsonData!,  complete:{
            result in
            self.currentAPITask = nil
            switch (result) {
            case .success(let (response,responseObject)):
                complete(.success((response,responseObject)))
            case .failure(let error):
                complete(.failure(error))
            }
        })


    }
    public func apiPost(_ api:String,json:Any,complete:@escaping IPaURLResourceUIResultHandler) {
        var jsonError:NSError?
        var jsonData:Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions())
        } catch let error as NSError {
            jsonError = error
            jsonData = nil
        }
        
        if let error = jsonError {
            complete(.failure(error))
            return
        }
        if let task = currentAPITask {
            if task.state == .running {
                task.cancel()
            }
        }
        
        currentAPITask = resourceUI.apiPost(api, contentType: "application/json", postData: jsonData!,  complete:{
            result in
            self.currentAPITask = nil
            switch (result) {
            case .success(let (response,responseObject)):
                complete(.success((response,responseObject)))
            case .failure(let error):
                complete(.failure(error))
            }
        })
    }
}

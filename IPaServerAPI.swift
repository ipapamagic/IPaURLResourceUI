//
//  IPaServerAPI.swift
//  IPaURLResourceUI
//
//  Created by IPa Chen on 2015/6/14.
//  Copyright (c) 2015年 IPaPa. All rights reserved.
//

import Foundation

class IPaServerAPI :NSObject {
    let resourceUI:IPaURLResourceUI
    var currentAPITask:URLSessionDataTask?
    init(resourceUI:IPaURLResourceUI) {
        self.resourceUI = resourceUI
    }
    func apiPerform(_ api:String,method:String,param:[String:AnyObject]?,complete:IPaURLResourceUISuccessHandler,failure:IPaURLResourceUIFailHandler) {
        
        if let task = currentAPITask {
            if task.state == .running {
                task.cancel()
            }
        }

        let aMethod = method.uppercased()
        if aMethod == "GET" {
            currentAPITask = resourceUI.apiGet(api, param:param, complete:{
                response,responseObject in
                self.currentAPITask = nil
                complete(response,responseObject)
                },failure:{
                    error in
                self.currentAPITask = nil
                    failure(error)
            })
        }
        else if aMethod == "POST" {
            currentAPITask = resourceUI.apiPost(api, param:param,  complete:{
                response,responseObject in
                self.currentAPITask = nil
                complete(response,responseObject)
                },failure:{
                    error in
                    self.currentAPITask = nil
                    failure(error)
            })
        }

    }
    func apiPut(_ api:String, json:AnyObject,complete:IPaURLResourceUISuccessHandler,failure:IPaURLResourceUIFailHandler) {
        var jsonError:NSError?
        var jsonData:Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions())
        } catch let error as NSError {
            jsonError = error
            jsonData = nil
        }
        
        if let error = jsonError {
            
            failure(error)
            
            return
        }
        if let task = currentAPITask {
            if task.state == .running {
                task.cancel()
            }
        }
        
        currentAPITask = resourceUI.apiPut(api, contentType: "application/json", postData: jsonData!,  complete:{
            response,responseObject in
            self.currentAPITask = nil
            complete(response,responseObject)
            },failure:{
                error in
                self.currentAPITask = nil
                failure(error)
        })


    }
    func apiPost(_ api:String,json:AnyObject,complete:IPaURLResourceUISuccessHandler,failure:IPaURLResourceUIFailHandler) {
        var jsonError:NSError?
        var jsonData:Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions())
        } catch let error as NSError {
            jsonError = error
            jsonData = nil
        }
        
        if let error = jsonError {
            
            failure(error)
            
            return
        }
        if let task = currentAPITask {
            if task.state == .running {
                task.cancel()
            }
        }
        
        currentAPITask = resourceUI.apiPost(api, contentType: "application/json", postData: jsonData!,  complete:{
            response,responseObject in
            self.currentAPITask = nil
            complete(response,responseObject)
            },failure:{
                error in
                self.currentAPITask = nil
                failure(error)
        })
    }
}

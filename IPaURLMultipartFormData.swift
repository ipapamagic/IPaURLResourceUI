//
//  IPaURLMultipartFormData.swift
//  IPaURLResourceUI
//
//  Created by IPa Chen on 2015/6/14.
//  Copyright (c) 2015年 IPaPa. All rights reserved.
//

import Foundation

open class IPaURLMultipartFormData {
    let boundary:String = ProcessInfo.processInfo.globallyUniqueString
    lazy var data:NSMutableData = NSMutableData()
    open func addStringData(_ string:String,name:String) {
        let dataString = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(string)\r\n"
        data.append(dataString.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
    }
    open func addFileData(_ fileData:Data,fileName:String,MIMEType:String,name:String) {
        let dataString = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\nContent-Type: \(MIMEType)\r\n\r\n"
        data.append(dataString.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        data.append(fileData)
        data.append("\r\n".data(using: String.Encoding.utf8, allowLossyConversion: false)!)
    }
    open func endOfBodyData() {
        let dataString = "--\(boundary)--\r\n"
        data.append(dataString.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        
    }
    
}

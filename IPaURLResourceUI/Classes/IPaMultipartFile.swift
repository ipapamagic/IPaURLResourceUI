//
//  IPaMultipartFile.swift
//  IPaURLResourceUI
//
//  Created by IPa Chen on 2015/6/14.
//  Copyright (c) 2015年 IPaPa. All rights reserved.
//

import Foundation
import MobileCoreServices

public struct IPaMultipartFile {
    public var name:String
    public var mime:String
    public var fileName:String
    var file:Any
    public var fileUrl:URL? {
        set {
            file = newValue as Any
        }
        get {
            return file as? URL
        }
    }
    public var filePath:String? {
        set {
            file = newValue as Any
        }
        get {
            return file as? String
        }
    }
    public var fileData:Data? {
        set {
            file = newValue as Any
        }
        get {
            return file as? Data
        }
    }
    var fileSize:Int {
        switch file {
        case let fileData as Data:
            return fileData.count
        case let filePath as String:
            let fileInfo =  try? FileManager.default.attributesOfItem(atPath: filePath)
            return (fileInfo?[FileAttributeKey.size] ?? 0) as! Int
        case let fileUrl as URL:
            let fileInfo =  try? FileManager.default.attributesOfItem(atPath: fileUrl.path)
            return (fileInfo?[FileAttributeKey.size] ?? 0) as! Int
        default:
            return 0
        }
    }
    public init(name:String,mime:String,fileName:String,fileUrl:URL) {
        self.name = name
        self.mime = mime
        self.fileName = fileName
        self.file = fileUrl
    }
    public init(name:String,mime:String,fileName:String,filePath:String) {
        self.name = name
        self.mime = mime
        self.fileName = fileName
        self.file = filePath
    }
    public init(name:String,mime:String,fileName:String,fileData:Data) {
        self.name = name
        self.mime = mime
        self.fileName = fileName
        self.file = fileData
    }
    public init(_ name:String,path:String) {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        self.mime = "application/octet-stream"
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                self.mime = mimetype as String
            }
        }
        self.fileName = (path as NSString).lastPathComponent
        self.name = name
        
        self.file = try! Data(contentsOf: url) as Any
    }
    func write(_ outputStream: OutputStream,boundary:String) {
        let dataString = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\nContent-Length: \(fileSize) \r\nContent-Type: \(mime)\r\n\r\n"
        guard let data = dataString.data(using: .utf8, allowLossyConversion: false) else {
            return
        }
        _ = data.withUnsafeBytes {
            outputStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
        }
        var inputFileStream:InputStream!
        switch file {
        case let filePath as String:
            inputFileStream = InputStream(fileAtPath: filePath)!
        case let fileUrl as URL:
            inputFileStream = InputStream(url: fileUrl)!
        case let fileData as Data:
            inputFileStream = InputStream(data: fileData)
        default:
            break
        }
        inputFileStream.open()
        let bufferSize = 65536
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        while inputFileStream.hasBytesAvailable {
            let readSize = inputFileStream.read(buffer, maxLength: bufferSize)
            if readSize < 0 {
                return
            } else if readSize == 0 {
                //EOF
                break
            }
            outputStream.write(buffer, maxLength: readSize)
            
        }
        inputFileStream.close()
        let endString = "\r\n"
        guard let endData = endString.data(using: .utf8, allowLossyConversion: false) else {
            return
        }
        _ = endData.withUnsafeBytes {
            outputStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: endData.count)
        }
    }
}

//
//  IPaURLResourceUIHelper.swift
//  IPaURLResourceUI
//
//  Created by IPa Chen on 2021/5/3.
//

import Foundation
import Combine
import IPaLog
extension IPaURLResourceUIResult {
    public var responseData:Data? {
        switch self {
        case .success(let (_,data)):
            return data
        case .failure(_):
            return nil
        }
    }
    public func jsonData<T>() -> T? {
        self.responseData?.jsonData as? T
    }
}
extension URLRequest {
    mutating func writeFormData(_ params:[String:Any] = [String:Any](),files:[IPaMultipartFile]) {
        var formData = Data()
        let boundary:String = ProcessInfo.processInfo.globallyUniqueString
        var dataString = ""
        for (key,value) in params {
            dataString += "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n"
        }
        if dataString.count > 0, let data = dataString.data(using: .utf8, allowLossyConversion: false) {
            formData.append(data)
        }
        for file in files {
            formData.append(file.generateFormData(boundary))
        }
        let endOfDataString = "--\(boundary)--\r\n"
        if let data = endOfDataString.data(using: .utf8, allowLossyConversion: false)  {
            formData.append(data)
        }
        self.httpBody = formData
    }
   
}
protocol IPaURLFormDataStreamWriter:StreamDelegate {
    var files:[IPaMultipartFile] {get}
    var params:[String:Any] {get}
    var tempFilePath:String {get}
    var _request:URLRequest {get set}
    func createOutputStream()
    func startURLConnection()
}
extension IPaURLFormDataStreamWriter
{
    func createOutputStream() {
        let outputStream = OutputStream(toFileAtPath: tempFilePath, append: false)!
        outputStream.delegate = self
        
        outputStream.schedule(in: RunLoop.main, forMode:.default)
        
        outputStream.open()
    }
    func streamDelegateFunction(_ aStream: Stream, handle eventCode: Stream.Event) {
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

@available(iOS 13.0, *)

extension URLSession.DataTaskPublisher {
    public func tryGoodResponse() -> Publishers.TryMap<Self, Output> {
        self.tryResponse(Set(arrayLiteral: 200),handle:{return $0})
    }
    public func tryGoodResponse<T>(_ handle: @escaping  ((Output) throws -> T)) -> Publishers.TryMap<Self, T> {
        self.tryResponse(Set(arrayLiteral: 200),handle:handle)
    }
   
    public func tryResponse<T>(_ whiteStatusCodes:Set<Int>,handle: @escaping ((URLSession.DataTaskPublisher.Output) throws -> T)) -> Publishers.TryMap<URLSession.DataTaskPublisher, T> {
        self.tryMap({
            value in
            guard let httpResponse = value.response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            guard whiteStatusCodes.contains(httpResponse.statusCode) else {
                let code = URLError.Code(rawValue: httpResponse.statusCode)
                throw URLError(code)
            }
            
            return try handle(value)
        })
    }
    public func tryGoodResponseJson<T>(_ type:T.Type) -> Publishers.TryMap<Self, T?> {
        self.tryGoodResponse { value in
            return value.data.jsonData as? T
        }
    }
    public func tryGoodResponseJsonDecodable<T:Decodable>(_ type:T.Type) -> Publishers.Decode<Publishers.TryMap<Self, JSONDecoder.Input>, T, JSONDecoder> {
        self.tryGoodResponse({
            value in
            return value.data
        }).decode(type: type, decoder: JSONDecoder())
    }
}

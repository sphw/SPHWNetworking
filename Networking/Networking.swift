//
//  Networking.swift
//  Networking
//

import Foundation
import CocoaAsyncSocket
import GZIP
enum NetworkingError: Error {
  case invalidUrl
}
open class NetworkingRequest: NSObject, GCDAsyncSocketDelegate {
//MARK: - HTTP Messages -
  var requestMessage: CFHTTPMessage?
  var responseMessage: CFHTTPMessage?
//MARK: - External Objects -
  var completionCB: (Response, CookieJar) -> ()?
  var progressCB: (_ progress: Int) -> ()
  var request: Request
  var response: Response?
//MARK: - Internal Objects -
  var socket: GCDAsyncSocket?
  var url: URL
  var bodyString: String = ""
  var cookieStore: CookieJar?
  var redirectCount: Int = 0
  var completed: Bool = false
//MARK; - Setup Functions -
  public init(request: Request, cookieStore: CookieJar, progressCB: @escaping (_ progress: Int) -> () = {progress in }, completion: @escaping (Response, CookieJar) -> ()) throws {
    self.url = URL(string: request.url)!
    self.completionCB = completion
    self.progressCB = progressCB
    self.request = request
    self.cookieStore = cookieStore
    super.init()
    guard self.url.host != nil else {
      throw NetworkingError.invalidUrl
    }
  }
  open func run() {
     responseMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, false).takeRetainedValue()
     requestMessage = CFHTTPMessageCreateRequest(kCFAllocatorDefault, request.rawMethod as CFString, CFURLCreateWithString(kCFAllocatorDefault, url.absoluteString as CFString!, nil), kCFHTTPVersion1_1).takeRetainedValue()
    if(request.timeout != 0) {
      Timer.scheduledTimer(timeInterval: request.timeout, target: self, selector: #selector(NetworkingRequest.timedOut(_:)), userInfo: nil, repeats: false)
    }
    response = Response()
    if((url as NSURL).port != 443 && (url as NSURL).port != 80 && (url as NSURL).port != nil) {
      CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, "Host" as CFString, "\(url.host!):\((url as NSURL).port!)" as CFString?)
    } else {
      CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, "Host" as CFString, url.host! as CFString?)
    }
    if(request.dataBody != nil) {
     CFHTTPMessageSetBody(requestMessage!, request.dataBody! as NSData as CFData)
     CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, "Content-Length" as CFString, "\((request.dataBody!.count))" as CFString)
    } else {
      if(request.body.characters.count > 0) {
        CFHTTPMessageSetBody(requestMessage!, request.body.data(using: String.Encoding.utf8)! as NSData as CFData)
        let data = request.body.data(using: String.Encoding.utf8)
        CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, "Content-Length" as CFString, "\((data!.count))" as CFString? )
      }
    }
    for header in request.headers {
      CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, header.key as CFString, header.value as CFString?)
    }
    if request.type == .JSON {
      CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, "Content-type" as CFString, "application/json" as CFString?)
    }
    let validCookies = cookieStore?.validCookies(self.url)
    let headerFields = HTTPCookie.requestHeaderFields(with: validCookies!)
    for (key, value): (String, String) in headerFields {
      NSLog("\(key): \(value)")
      CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, key as CFString, value as CFString)
    }
    let queue = DispatchQueue(label: "com.networking.queue\(arc4random_uniform(1000))", attributes: [])
    self.socket = GCDAsyncSocket(delegate: self, delegateQueue: queue, socketQueue: queue)
    var host = url.host
    var port: Int
    if(self.url.scheme == "https") {
      port = (url as NSURL).port?.intValue ?? 443
    } else {
      port = (url as NSURL).port?.intValue ?? 80
    }
    if(request.proxy != "") {
      let proxyURL = URL(string: request.proxy)
      host = proxyURL?.host
      CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, "Proxy-Connection" as CFString, "keep-alive" as CFString?)
      if((proxyURL as NSURL?)?.port != nil) {
        port = ((proxyURL as NSURL?)?.port?.intValue)!
      }
    }
    if(request.interface == "") {
      try! socket!.connect(toHost: host, onPort: UInt16(port), withTimeout: -1)
    } else {
      try! socket!.connect(toHost: host, onPort: UInt16(port), viaInterface: request.interface, withTimeout: -1)
    }
    if(self.url.scheme == "https") {
        self.socket!.startTLS([ String(kCFStreamSSLPeerName): host!])
    }
  }
//MARK: - Socket Delegates -
  open func socket(_ sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
    print("Connected to URL: \(self.url)")
    if let data = CFHTTPMessageCopySerializedMessage(self.requestMessage!) {
      let rData = data.takeRetainedValue()
      var string = String(data: rData as Data, encoding: String.Encoding.utf8)
      if(request.proxy == "") {
        socket!.write(rData as Data, withTimeout: -1, tag: 0)
      } else {
        var array = string?.components(separatedBy: "\r\n")
        array![0] = "\(request.rawMethod) \(url.absoluteString) HTTP/1.1"
        string = array?.joined(separator: "\r\n")

      }
      self.progressCB(25)
      socket!.readData(to: "\r\n\r\n".data(using: String.Encoding.ascii), withTimeout: -1, tag: 1)

    }
  }
  open func socket(_ sock: GCDAsyncSocket!, didRead data: Data!, withTag tag: Int) {
    data.withUnsafeBytes() { (bytes: UnsafePointer<UInt8>) -> Void in
      if let string = String(data: data, encoding: String.Encoding.ascii) {
        CFHTTPMessageAppendBytes(self.responseMessage!, bytes, data.count)
        if(tag == 1) {
          if let encoding = CFHTTPMessageCopyHeaderFieldValue(self.responseMessage!, "Transfer-Encoding" as CFString) {
            if encoding.takeRetainedValue() as String == "chunked" {
              socket?.readData(to: "\r\n".data(using: String.Encoding.ascii), withTimeout: -1, tag: 3)
              NSLog("reading forward chunked")
            }
          } else if let length = (CFHTTPMessageCopyHeaderFieldValue(self.responseMessage!, "Content-Length" as CFString)) {
            let intLength = UInt(length.takeRetainedValue() as String)
            if(intLength == 0) {
              self.requestFinished()
            }
            socket!.readData(toLength: intLength!, withTimeout: -1, tag: 2)
            NSLog("reading forward length")
          } else {
            self.requestFinished()
          }
          self.progressCB(35)
        }
        if(tag == 2) {
          self.response!.body += string
          self.response!.dataBody.append(data)
          self.requestFinished()
        }
        if(tag == 3) {
          if let length = UInt(string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), radix: 16) {
            if(length != 0) {
              socket!.readData(toLength: length, withTimeout: -1, tag: 4)
            } else {
              self.requestFinished()
            }
          }
        }
        let dataCar = "\r\n".data(using: String.Encoding.ascii)
        if(tag == 4) {
          self.response!.body += string
          self.response!.dataBody.append(data)
          socket?.readData(to: dataCar, withTimeout: -1, tag: 5)
        }
        if(tag == 5) {
          socket?.readData(to: dataCar, withTimeout: -1, tag: 3)
          self.progressCB(55)
        }
      }
    }
  }
  open func socketDidDisconnect(_ sock: GCDAsyncSocket!, withError err: NSError!) {
    NSLog("Disconnected")
    if(completed == false) {
      self.responseGenerator()
    }
  }
//MARK: - Handlers
  func requestFinished() {
    print("Finished: \(self.url)")
    let statusCode = CFHTTPMessageGetResponseStatusCode(self.responseMessage!)
    if  statusCode == 301 || statusCode == 302 || statusCode == 307 || statusCode == 308 {
      if let location = CFHTTPMessageCopyHeaderFieldValue(self.responseMessage!, "Location" as CFString)?.takeRetainedValue() {
        if(redirectCount < self.request.maxRedirects) {
          let oldUrl = url
          self.url = URL(string: location as String, relativeTo: oldUrl)!
          self.redirectCount += 1
          self.responseMessage = nil
          completed = true
          self.run()
        } else {
          self.responseGenerator()
        }
      }
    } else {
      self.responseGenerator()
    }
  }
  func responseGenerator() {
    let statusCode = CFHTTPMessageGetResponseStatusCode(self.responseMessage!)
    self.completed = true
    response!.url = self.url.absoluteString
//    response!.size = (self.response!.body.dataUsingEncoding(NSASCIIStringEncoding)?.length)!;
    response!.statusCode = statusCode
    response!.redirectCount = redirectCount
    if let headerCFDict = CFHTTPMessageCopyAllHeaderFields(self.responseMessage!)?.takeRetainedValue() as NSDictionary? {
      let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerCFDict as! [String : String], for: self.url)
      self.cookieStore?.addCookies(cookies)
      for rawKey in headerCFDict.allKeys {
        let key = rawKey as! String as String!
        let value = (headerCFDict.value(forKey: key!) as! String)
        response!.headers.append(KVPair(key: key!, value: value))
        switch (key?.lowercased()) {
        case "content-type"?:
          if(value.lowercased().contains("application/json")) {
            response!.type = Type.JSON
          } else {
            response!.type = Type.PlainText
          }
        default: break
        }
      }
    }
    completionCB(response!, cookieStore!)
    self.progressCB(100)
  }
  func errorHandler(_ error: String) {
  }
  func timedOut(_ timer: Timer) {
    self.completed = true
    socket!.disconnect()
    response!.body = "TIMEDOUT"
    completionCB(response!, cookieStore!)
    self.progressCB(100)
  }
}
public enum Type: String {
  case JSON, XML, URLEncoded = "URL Encoded", PlainText = "Plain Text", HTML
}
public enum FollowRedirect {
  case all
  case get
}
open class HttpAuth: NSObject {
  open var username: String = ""
  open var password: String = ""
  public init(username: String, password: String) {
    self.username = username
    self.password = password
  }
}
public enum Method: String {
  case OPTIONS, GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT
}
open class KVPair: NSObject {
  open var key: String = ""
  open var value: String = ""
  public init(key: String, value: String) {
    self.key = key
    self.value = value
  }
}

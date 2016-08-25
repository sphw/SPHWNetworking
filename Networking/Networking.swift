//
//  Networking.swift
//  Networking
//

import Foundation
import CocoaAsyncSocket
import GZIP
enum NetworkingError: ErrorType {
  case InvalidUrl
}
public class NetworkingRequest: NSObject, GCDAsyncSocketDelegate {
//MARK: - HTTP Messages -
  var requestMessage: CFHTTPMessage?
  var responseMessage: CFHTTPMessage?
//MARK: - External Objects -
  var completionCB: (Response, CookieJar) -> ()?
  var progressCB: (progress: Int) -> ()
  var request: Request
  var response: Response?
//MARK: - Internal Objects -
  var socket: GCDAsyncSocket?
  var url: NSURL
  var bodyString: String = ""
  var cookieStore: CookieJar?
  var redirectCount: Int = 0
  var completed: Bool = false
//MARK; - Setup Functions -
  public init(request: Request, cookieStore: CookieJar, progressCB: (progress: Int) -> () = {progress in }, completion: (Response, CookieJar) -> ()) throws {
    self.url = NSURL(string: request.url)!
    self.completionCB = completion
    self.progressCB = progressCB
    self.request = request
    self.cookieStore = cookieStore
    super.init()
    guard self.url.host != nil else {
      throw NetworkingError.InvalidUrl
    }
  }
  public func run() {
     responseMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, false).takeRetainedValue()
     requestMessage = CFHTTPMessageCreateRequest(kCFAllocatorDefault, request.rawMethod, CFURLCreateWithString(kCFAllocatorDefault, url.absoluteString, nil), kCFHTTPVersion1_1).takeRetainedValue()
    if(request.timeout != 0) {
      NSTimer.scheduledTimerWithTimeInterval(request.timeout, target: self, selector: "timedOut:", userInfo: nil, repeats: false)
    }
    response = Response()
    if(url.port != 443 && url.port != 80 && url.port != nil) {
      CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, "Host", "\(url.host!):\(url.port!)")
    } else {
      CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, "Host", url.host!)
    }
    if(request.dataBody != nil) {
     CFHTTPMessageSetBody(requestMessage!, request.dataBody!)
     CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, "Content-Length", "\((request.dataBody!.length))")
    } else {
      if(request.body.characters.count > 0) {
        CFHTTPMessageSetBody(requestMessage!, request.body.dataUsingEncoding(NSUTF8StringEncoding)!)
        let data = request.body.dataUsingEncoding(NSUTF8StringEncoding)
        CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, "Content-Length", "\((data!.length))" )
      }
    }
    for header in request.headers {
      CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, header.key, header.value)
    }
    if request.type == .JSON {
      CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, "Content-type", "application/json")
    }
    let validCookies = cookieStore?.validCookies(self.url)
    let headerFields = NSHTTPCookie.requestHeaderFieldsWithCookies(validCookies!)
    for (key, value): (String, String) in headerFields {
      NSLog("\(key): \(value)")
      CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, key, value)
    }
    let queue = dispatch_queue_create("com.networking.queue\(arc4random_uniform(1000))", nil)
    self.socket = GCDAsyncSocket(delegate: self, delegateQueue: queue, socketQueue: queue)
    var host = url.host
    var port: Int
    if(self.url.scheme == "https") {
      port = url.port?.integerValue ?? 443
    } else {
      port = url.port?.integerValue ?? 80
    }
    if(request.proxy != "") {
      let proxyURL = NSURL(string: request.proxy)
      host = proxyURL?.host
      CFHTTPMessageSetHeaderFieldValue(self.requestMessage!, "Proxy-Connection", "keep-alive")
      if(proxyURL?.port != nil) {
        port = (proxyURL?.port?.integerValue)!
      }
    }
    if(request.interface == "") {
      try! socket!.connectToHost(host, onPort: UInt16(port), withTimeout: -1)
    } else {
      try! socket!.connectToHost(host, onPort: UInt16(port), viaInterface: request.interface, withTimeout: -1)
    }
    if(self.url.scheme == "https") {
        self.socket!.startTLS([ String(kCFStreamSSLPeerName): host!])
    }
  }
//MARK: - Socket Delegates -
  public func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
    print("Connected to URL: \(self.url)")
    if let data = CFHTTPMessageCopySerializedMessage(self.requestMessage!) {
      let rData = data.takeRetainedValue()
      var string = String(data: rData, encoding: NSUTF8StringEncoding)
      if(request.proxy == "") {
        socket!.writeData(rData, withTimeout: -1, tag: 0)
      } else {
        var array = string?.componentsSeparatedByString("\r\n")
        array![0] = "\(request.rawMethod) \(url.absoluteString) HTTP/1.1"
        string = array?.joinWithSeparator("\r\n")

      }
      self.progressCB(progress: 25)
      socket!.readDataToData("\r\n\r\n".dataUsingEncoding(NSASCIIStringEncoding), withTimeout: -1, tag: 1)

    }
  }
  public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
    if(data.bytes != nil) {
      if let string = String(data: data, encoding: NSASCIIStringEncoding) {
        CFHTTPMessageAppendBytes(self.responseMessage!, UnsafePointer<UInt8>(data.bytes), data.length)
        if(tag == 1) {
          if let encoding = CFHTTPMessageCopyHeaderFieldValue(self.responseMessage!, "Transfer-Encoding") {
            if encoding.takeRetainedValue() == "chunked" {
              socket?.readDataToData("\r\n".dataUsingEncoding(NSASCIIStringEncoding), withTimeout: -1, tag: 3)
              NSLog("reading forward chunked")
            }
          } else if let length = (CFHTTPMessageCopyHeaderFieldValue(self.responseMessage!, "Content-Length")) {
            let intLength = UInt(length.takeRetainedValue() as String)
            if(intLength == 0) {
              self.requestFinished()
            }
            socket!.readDataToLength(intLength!, withTimeout: -1, tag: 2)
            NSLog("reading forward length")
          } else {
            self.requestFinished()
          }
          self.progressCB(progress: 35)
        }
        if(tag == 2) {
          self.response!.body += string
          self.response!.dataBody.appendData(data)
          self.requestFinished()
        }
        if(tag == 3) {
          if let length = UInt(string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()), radix: 16) {
            if(length != 0) {
              socket!.readDataToLength(length, withTimeout: -1, tag: 4)
            } else {
              self.requestFinished()
            }
          }
        }
        let dataCar = "\r\n".dataUsingEncoding(NSASCIIStringEncoding)
        if(tag == 4) {
          self.response!.body += string
          self.response!.dataBody.appendData(data)
          socket?.readDataToData(dataCar, withTimeout: -1, tag: 5)
        }
        if(tag == 5) {
          socket?.readDataToData(dataCar, withTimeout: -1, tag: 3)
          self.progressCB(progress: 55)
        }
      }
    }
  }
  public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
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
      if let location = CFHTTPMessageCopyHeaderFieldValue(self.responseMessage!, "Location")?.takeRetainedValue() {
        if(redirectCount < self.request.maxRedirects) {
          let oldUrl = url
          self.url = NSURL(string: location as String, relativeToURL: oldUrl)!
          self.redirectCount++
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
    response!.url = self.url.absoluteString!
//    response!.size = (self.response!.body.dataUsingEncoding(NSASCIIStringEncoding)?.length)!;
    response!.statusCode = statusCode
    response!.redirectCount = redirectCount
    if let headerCFDict = CFHTTPMessageCopyAllHeaderFields(self.responseMessage!)?.takeRetainedValue() as NSDictionary? {
      let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(headerCFDict as! [String : String], forURL: self.url)
      self.cookieStore?.addCookies(cookies)
      for rawKey in headerCFDict.allKeys {
        let key = rawKey as! String as String!
        let value = (headerCFDict.valueForKey(key) as! String)
        response!.headers.append(KVPair(key: key, value: value))
        switch (key.lowercaseString) {
        case "content-type":
          if(value.lowercaseString.containsString("application/json")) {
            response!.type = Type.JSON
          } else {
            response!.type = Type.PlainText
          }
        default: break
        }
      }
    }
    completionCB(response!, cookieStore!)
    self.progressCB(progress: 100)
  }
  func errorHandler(error: String) {
  }
  func timedOut(timer: NSTimer) {
    self.completed = true
    socket!.disconnect()
    response!.body = "TIMEDOUT"
    completionCB(response!, cookieStore!)
    self.progressCB(progress: 100)
  }
}
public enum Type: String {
  case JSON, XML, URLEncoded = "URL Encoded", PlainText = "Plain Text", HTML
}
public enum FollowRedirect {
  case All
  case Get
}
public class HttpAuth: NSObject {
  public var username: String = ""
  public var password: String = ""
  public init(username: String, password: String) {
    self.username = username
    self.password = password
  }
}
public enum Method: String {
  case OPTIONS, GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT
}
public class KVPair: NSObject {
  public var key: String = ""
  public var value: String = ""
  public init(key: String, value: String) {
    self.key = key
    self.value = value
  }
}

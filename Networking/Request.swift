//
//  Request.swift
//  Networking
//
//  Created by Sascha Wise on 12/5/15.
//  Copyright © 2015 SW. All rights reserved.
//

import Foundation
public class Request: NSObject{
  /** The HTTP method ***/
  public var method: Method = .GET {
    didSet {
      rawMethod = method.rawValue;
    }
  };
  public var rawMethod: String = "GET" {
    didSet{
      if(oldValue != self.rawMethod){
        if let _method = Method(rawValue: rawMethod) {
          method = _method;
        }
      }
    }
  };
  public var url: String = "";
  public var httpAuth: HttpAuth = HttpAuth(username: "", password: "");
  public dynamic var headers: [KVPair] = [KVPair]();
  public var type: Type = Type.PlainText
  public dynamic var body: String {
    get {
        return plainTextBody;
    }
    set(bodyString) {
      plainTextBody = bodyString;
    }
  }
  /** The dataBody which when not empty takes precedent over the plainTextBody **/
  public var dataBody: NSData?
  public var plainTextBody: String = "";
//  public var gzip: Bool = false;
  public var timeout: Double = 0;
//  public var followRedirect: FollowRedirect =  FollowRedirect.Get;
  public var maxRedirects: Int = 10;
  public var proxy: String = "";
  public var interface: String = "";
}
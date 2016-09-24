//
//  Request.swift
//  Networking
//
//  Created by Sascha Wise on 12/5/15.
//  Copyright © 2015 SW. All rights reserved.
//

import Foundation
open class Request: NSObject{
  /** The HTTP method ***/
  open var method: Method = .GET {
    didSet {
      rawMethod = method.rawValue;
    }
  };
  open var rawMethod: String = "GET" {
    didSet{
      if(oldValue != self.rawMethod){
        if let _method = Method(rawValue: rawMethod) {
          method = _method;
        }
      }
    }
  };
  open var url: String = "";
  open var httpAuth: HttpAuth = HttpAuth(username: "", password: "");
  open dynamic var headers: [KVPair] = [KVPair]();
  open var type: Type = Type.PlainText
  open dynamic var body: String {
    get {
        return plainTextBody;
    }
    set(bodyString) {
      plainTextBody = bodyString;
    }
  }
  /** The dataBody which when not empty takes precedent over the plainTextBody **/
  open var dataBody: Data?
  open var plainTextBody: String = "";
//  public var gzip: Bool = false;
  open var timeout: Double = 0;
//  public var followRedirect: FollowRedirect =  FollowRedirect.Get;
  open var maxRedirects: Int = 10;
  open var proxy: String = "";
  open var interface: String = "";
}

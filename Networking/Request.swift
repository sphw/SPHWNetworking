//
//  Request.swift
//  Networking
//
//  Created by Sascha Wise on 12/5/15.
//  Copyright © 2015 SW. All rights reserved.
//

import Foundation
class Request: NSObject{
  var method: Method = .GET {
    didSet {
      rawMethod = method.rawValue;
    }
  };
  var rawMethod: String = "GET" {
    didSet{
      if(oldValue != self.rawMethod){
        if let _method = Method(rawValue: rawMethod) {
          method = _method;
        }
      }
    }
  };
  var url: String = "";
  var httpAuth: HttpAuth = HttpAuth(username: "", password: "");
   dynamic var headers: [KVPair] = [KVPair]();
  var type: Type = Type.PlainText {
    didSet {
      rawType = type.rawValue;
    }
  }
  var rawType: String = "Plain Text" {
    didSet {
      if(oldValue != self.rawType){
        if let _type = Type(rawValue: rawType) {
          type = _type;
        }
      }
    }
  }
  var plainTextBody: String = "";
  dynamic var body: String {
    get {
        return plainTextBody;
    }
    set(bodyString) {
      plainTextBody = bodyString;
    }
  }
  var dataBody: NSData?
  var gzip: Bool = false;
  var timeout: Double = 0;
  var followRedirect: FollowRedirect =  FollowRedirect.Get;
  var maxRedirects: Int = 10;
  var proxy: String = "";
  var interface: String = "";
}
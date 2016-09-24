//
//  Cookie.swift
//  Networking
//
//  Created by Sascha Wise on 11/16/15.
//  Copyright © 2015 SW. All rights reserved.
//

import Cocoa
open class CookieJar: NSObject {
  open var cookies: Array<HTTPCookie> = [];
  open func addCookies(_ newCookies: [HTTPCookie]){
    for newCookie in newCookies {
      var added = false
      for  cookie in self.cookies {
        if(cookie.name == newCookie.name){
          self.cookies[self.cookies.index(of: cookie)!] = newCookie;
          added = true
        }
      }
      if(!added){
        self.cookies.append(newCookie);
      }
    }
    NSLog("added");
  }
  open func validCookies(_ url: URL) -> [HTTPCookie]{
     let ary = self.cookies.filter({ cookie in
      var validity = true
      if cookie.domain.characters.first == "." {
        validity = (url.host?.contains(cookie.domain))!
      }else{
        validity =  (cookie.domain == url.host)
      }
      NSLog(cookie.path);
      if(cookie.path != "/"){
        for (i, pathComponent) in cookie.path.components(separatedBy: "/").enumerated(){
          let urlComponent = url.pathComponents[i];
          if(validity){
            var tP = pathComponent
            if(pathComponent == ""){
              tP = "/"
            }
            validity = (tP == urlComponent);
          }
        }
      }
      return validity
    })
    return ary
  }
}

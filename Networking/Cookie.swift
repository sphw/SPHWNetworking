//
//  Cookie.swift
//  Networking
//
//  Created by Sascha Wise on 11/16/15.
//  Copyright © 2015 SW. All rights reserved.
//

import Cocoa
public class CookieJar: NSObject {
  public var cookies: Array<NSHTTPCookie> = [];
  public func addCookies(newCookies: [NSHTTPCookie]){
    for newCookie in newCookies {
      var added = false
      for  cookie in self.cookies {
        if(cookie.name == newCookie.name){
          self.cookies[self.cookies.indexOf(cookie)!] = newCookie;
          added = true
        }
      }
      if(!added){
        self.cookies.append(newCookie);
      }
    }
    NSLog("added");
  }
  public func validCookies(url: NSURL) -> [NSHTTPCookie]{
     let ary = self.cookies.filter({ cookie in
      var validity = true
      if cookie.domain.characters.first == "." {
        validity = (url.host?.containsString(cookie.domain))!
      }else{
        validity =  (cookie.domain == url.host)
      }
      NSLog(cookie.path);
      if(cookie.path != "/"){
        for (i, pathComponent) in cookie.path.componentsSeparatedByString("/").enumerate(){
          let urlComponent = url.pathComponents![i];
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
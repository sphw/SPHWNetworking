//
//  Cookie.swift
//  Networking
//
//  Created by Sascha Wise on 11/16/15.
//  Copyright © 2015 SW. All rights reserved.
//

import Cocoa
public class CookieJar: NSObject {
  var cookies: Array<NSHTTPCookie> = [];
  var name: String;
  init(name: String){
    self.name = name;
  }
  func addCookies(newCookies: [NSHTTPCookie]){
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
  func toDict() -> NSMutableDictionary{
    var cookiesArray = [NSMutableDictionary]()
    let dateFormatter = NSDateFormatter();
    for cookie in cookies {
      cookiesArray.append([
        NSHTTPCookieDomain: cookie.domain,
//        NSHTTPCookieExpires: dateFormatter.stringFromDate(cookie.expiresDate!),
        NSHTTPCookieName: cookie.name,
        NSHTTPCookiePath: cookie.path,
        NSHTTPCookieSecure: cookie.secure,
        NSHTTPCookieValue: cookie.value,
        NSHTTPCookieVersion: cookie.version
        ]);
    }
    return [
      "cookies": cookiesArray,
      "name": self.name,
    ]
  }
  func validCookies(url: NSURL) -> [NSHTTPCookie]{
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
//
//  Response.swift
//  Networking
//
//  Created by Sascha Wise on 12/5/15.
//  Copyright © 2015 SW. All rights reserved.
//

import Foundation
class Response : NSObject {
  /// The body. This is always a string, and then is convereted into different formats as needed.
  var body: String = "";
  var dataBody: NSMutableData = NSMutableData();
  /** The Syntax Highlighet format **/
  var format: Int = 0;
  /** The types of the response. These are automaticly found by getting the content-type editor.
   - Default: PlainText
   **/
  var type: Type = .PlainText {
  didSet {
    rawType = type.rawValue;
  }
  };
  var rawType: String = "" {
  didSet{
    if(oldValue != self.rawType){
    if let _type = Type(rawValue: rawType) {
      type = _type;
    }
    }
  }
  };
  var url: String = "";
  var size: Int = 0;
  var date: NSDate = NSDate();
  var time: Float32 = 0.0;
  var statusCode: Int! = 0 {
    didSet {
      if(statusCode != 0){
        self.statusString =  "\(statusCode)";
      }else{
        self.statusString = "";
      }
    }
  };
  var statusString: String = "";
  var success: Bool = false;
  var redirectCount: Int = 0;
  var headers: Array<KVPair> = [];
}
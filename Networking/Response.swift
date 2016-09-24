//
//  Response.swift
//  Networking
//
//  Created by Sascha Wise on 12/5/15.
//  Copyright © 2015 SW. All rights reserved.
//

import Foundation
open class Response : NSObject {
  /// The body. This is always a string, and then is convereted into different formats as needed.
  open var body: String = "";
  /** This is a NSData body. When present it will be sent instent of body **/
  open var dataBody: NSMutableData = NSMutableData();
  /** The Syntax Highlighet format **/
  open var format: Int = 0;
  /** The types of the response. These are automaticly found by getting the content-type editor.
   - Default: PlainText
   **/
  open var type: Type = .PlainText
  /** The URL for the response
   - Default: The URL of the request
   **/
  open var url: String = "";
  /** The size in bytes of the response **/
  open var size: Int = 0;
  /** The date that the response object was created **/
  open var date: Date = Date();
  /** The length of time it took to complete the request **/
  open var time: Float32 = 0.0;
  /** The HTTP status code **/
  open var statusCode: Int! = 0 {
    didSet {
      if(statusCode != 0){
        self.statusString =  "\(statusCode)";
      }else{
        self.statusString = "";
      }
    }
  };
  /** A string version of the status code with a default value of blank instead of 0 **/
  open var statusString: String = "";
  /** A boolean value for whether or not the request has succeded true means a statusCode of below 400 **/
  open var success: Bool = false;
  /** The number of redirects the response follow **/
  open var redirectCount: Int = 0;
  /** The headers **/
  open var headers: Array<KVPair> = [];
}

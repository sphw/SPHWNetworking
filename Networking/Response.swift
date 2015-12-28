//
//  Response.swift
//  Networking
//
//  Created by Sascha Wise on 12/5/15.
//  Copyright © 2015 SW. All rights reserved.
//

import Foundation
public class Response : NSObject {
  /// The body. This is always a string, and then is convereted into different formats as needed.
  public var body: String = "";
  /** This is a NSData body. When present it will be sent instent of body **/
  public var dataBody: NSMutableData = NSMutableData();
  /** The Syntax Highlighet format **/
  public var format: Int = 0;
  /** The types of the response. These are automaticly found by getting the content-type editor.
   - Default: PlainText
   **/
  public var type: Type = .PlainText
  /** The URL for the response
   - Default: The URL of the request
   **/
  public var url: String = "";
  /** The size in bytes of the response **/
  public var size: Int = 0;
  /** The date that the response object was created **/
  public var date: NSDate = NSDate();
  /** The length of time it took to complete the request **/
  public var time: Float32 = 0.0;
  /** The HTTP status code **/
  public var statusCode: Int! = 0 {
    didSet {
      if(statusCode != 0){
        self.statusString =  "\(statusCode)";
      }else{
        self.statusString = "";
      }
    }
  };
  /** A string version of the status code with a default value of blank instead of 0 **/
  public var statusString: String = "";
  /** A boolean value for whether or not the request has succeded true means a statusCode of below 400 **/
  public var success: Bool = false;
  /** The number of redirects the response follow **/
  public var redirectCount: Int = 0;
  /** The headers **/
  public var headers: Array<KVPair> = [];
}
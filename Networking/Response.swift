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
  public var url: String = "";
  public var size: Int = 0;
  public var date: NSDate = NSDate();
  public var time: Float32 = 0.0;
  public var statusCode: Int! = 0 {
    didSet {
      if(statusCode != 0){
        self.statusString =  "\(statusCode)";
      }else{
        self.statusString = "";
      }
    }
  };
  public var statusString: String = "";
  public var success: Bool = false;
  public var redirectCount: Int = 0;
  public var headers: Array<KVPair> = [];
}
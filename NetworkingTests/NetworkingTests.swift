//
//  NetworkingTests.swift
//  NetworkingTests
//
//  Created by Sascha Wise on 12/26/15.
//  Copyright © 2015 SW. All rights reserved.
//

import XCTest
@testable import Networking

class NetworkingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
  var cookieJar = CookieJar(name: "Test");
  var netRequest: NetworkingRequest?;
  func testHttpRequestStatusCode() {
    let request: Request = Request();
    request.url = "https://httpbin.org/status/404";
    request.method = .GET;
    let readyExpectation = expectation(description: "status code")
    netRequest = try! NetworkingRequest(request: request, cookieStore: self.cookieJar, completionCB: { response, jar in
      XCTAssertEqual(response.statusCode, 404);
      readyExpectation.fulfill();
      }, progressCB: {progress in});
    netRequest?.run();
    waitForExpectations(timeout: 20, handler: { error in
      XCTAssertNil(error, "Error")
    });
  }
  func testHTTPRediret() {
    let request: Request = Request();
    request.url = "https://httpbin.org/redirect/2";
    request.method = .GET;
    request.maxRedirects = 10;
    let readyExpectation = expectation(description: "status code")
    netRequest = try! NetworkingRequest(request: request, cookieStore: self.cookieJar, completionCB: { response, jar in
      XCTAssertEqual(response.url, "https://httpbin.org/get");
      readyExpectation.fulfill();
      }, progressCB: {progress in});
    netRequest?.run();
    waitForExpectations(timeout: 20, handler: { error in
      XCTAssertNil(error, "Error")
    });
    
  }
  func testHTTPMaxRedirect() {
    let request: Request = Request();
    request.url = "https://httpbin.org/redirect/10";
    request.method = .GET;
    request.maxRedirects = 5;
    let readyExpectation = expectation(description: "status code")
    netRequest = try! NetworkingRequest(request: request, cookieStore: self.cookieJar, completionCB: { response, jar in
      XCTAssertEqual(response.url, "https://httpbin.org/relative-redirect/5");
      readyExpectation.fulfill();
      }, progressCB: {progress in});
    netRequest?.run();
    waitForExpectations(timeout: 40, handler: { error in
      XCTAssertNil(error, "Error")
    });
  }
  func testUnsecureHTTP(){
    let request: Request = Request();
    request.url = "http://httpbin.org/status/200";
    request.method = .GET;
    let readyExpectation = expectation(description: "status code")
    netRequest = try! NetworkingRequest(request: request, cookieStore: self.cookieJar, completionCB: { response, jar in
      XCTAssertEqual(response.statusCode, 200);
      readyExpectation.fulfill();
      }, progressCB: {progress in});
    netRequest?.run();
    waitForExpectations(timeout: 20, handler: { error in
      XCTAssertNil(error, "Error")
    });
  }
  func testCookieSending(){
    if let cookie = HTTPCookie.init(properties: [HTTPCookiePropertyKey.originURL: "https://httpbin.org", HTTPCookiePropertyKey.name: "test", HTTPCookiePropertyKey.value: "test", HTTPCookiePropertyKey.path: "/"]){
      let testJar = CookieJar(name: "Test");
      testJar.addCookies([cookie])
      let request: Request = Request();
      request.url = "https://httpbin.org/cookies";
      request.method = .GET;
      let readyExpectation = expectation(description: "cookie failed")
      netRequest = try! NetworkingRequest(request: request, cookieStore: testJar, completionCB: { response, jar in
        NSLog(response.body);
        XCTAssertEqual(response.body.containsString("\"test\": \"test\""), true);
        readyExpectation.fulfill();
        }, progressCB: {progress in});
      netRequest?.run();
      waitForExpectations(timeout: 5, handler: { error in
        XCTAssertNil(error, "Error")
      })
    }
  }
  func testCookieJarPathSuccess(){
    let testJar = CookieJar(name: "Test");
    if let cookie = HTTPCookie.init(properties: [HTTPCookiePropertyKey.originURL: "http://google.com", HTTPCookiePropertyKey.name: "test", HTTPCookiePropertyKey.value: "test", HTTPCookiePropertyKey.path: "/test"]){
      testJar.addCookies([cookie]);
      var validCookies = testJar.validCookies(URL(string: "http://google.com/test")!);
      XCTAssert(validCookies[0].name == "test");
    }
  }
  func testCookieJarPathFail(){
    let testJar = CookieJar(name: "Test");
    if let cookie = HTTPCookie.init(properties: [HTTPCookiePropertyKey.originURL: "http://google.com", HTTPCookiePropertyKey.name: "test", HTTPCookiePropertyKey.value: "test", HTTPCookiePropertyKey.path: "/blah"]){
      testJar.addCookies([cookie]);
      let validCookies = testJar.validCookies(URL(string: "http://google.com/test")!);
      XCTAssert(validCookies.count == 0);
    }
  }
  
}

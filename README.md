## SPHWNetworking 
SWNetworking is an easy to use Swift HTTP client built with CocoaAsyncSockets. It is in the alpha stages and as such the API is going to change. It was built for [Intercept][1] and RESTer

### Install
---
SPHWNetworking can be installed easily via cocoa pods

```ruby
pod 'SPHWNetworking'
```
### Usage
---
The basic usage of it is simple. You first create a request object, and to set a URL; then a method.

```swift
var request = Request()
request.url = "http://google.com"
request.method = .GET
```
`Then you can setup the body, which can come in two forms NSData or a string. The NSData takes precedent over the string

```swift
request.dataBody = NSData()
```
**OR**


```swift
request.body = "FOO"
```
Last but not least you setup your networking request.

```swift
let netRequest = NetworkingRequest(request, jar: CookieJar(), completionCB: {
response, jar in
// Do stuff with the resulting jar and response
}, progressCB: { progress in
// Do stuff with the progress
})
```
[1]:	http://intercept.saschawise.com
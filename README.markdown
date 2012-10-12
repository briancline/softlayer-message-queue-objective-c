SoftLayer Messaging Queue - iOS and Mac OS X
============================================

This repository includes the SoftLayer Messaging Queue for iOS and MacOS X.  Included in the repository are sources for a MacOS X framework and an iOS static library each of which include Objective-C classes for working with the [SoftLayer Messaging Queue API](http://sldn.softlayer.com/reference/messagequeueapi). Also included are two sample projects, one for iOS and one for Mac OS X, which demonstrate how to call routines in the Messaging Queue API. All four projects are collected together in the XCode workspace titled SLMessaging.xcworkspace.

The projects were developed using XCode 4.5.  The iOS projects rely on the iOS 6 SDK and the MacOS X projects were built to the MacOS X 10.8 SDK.

Requests to the messaging API within the libraries are handled asynchronously with responses delivered through blocks.  The general form of a call is:

```objective-c
- (id<SLCancelableOperation) requestSomethingOfTheAPI: (NSString *) parameter
                                                queue: (NSOperationQueue *) completionQueue
                                    completionHandler: ((^)(NSString *completionParameters)) completionHandler;
```									

With this call, the library makes an asynchronous HTTP request to the server to satisfy the request.  When completed, the `completionHandler` block will be posted on the NSOperationQueue identified by `completionQueue`.  The value returned by the call is an HTTP request object that may be cancelled should the need arise.


Need more help?
---------------

For additional guidance and information, check out the
[Message Queue API reference](http://sldn.softlayer.com/reference/messagequeueapi) 
or the [SoftLayer Developer Network forum](https://forums.softlayer.com/forumdisplay.php?f=27).

For specific issues with the Ruby client library, get in touch with us via the
[SoftLayer Developer Network forum](https://forums.softlayer.com/forumdisplay.php?f=27)
or the [Issues page on our GitHub repository](https://github.com/softlayer/softlayer-message-queue-objective-c/issues).

License
-------

Copyright (c) 2012 SoftLayer Technologies, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

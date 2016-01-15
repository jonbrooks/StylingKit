/****************************************************************************
 *
 * Copyright 2015-present StylingKit Development Team. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 ****************************************************************************/

//
// Created by Anton Matosov
//

#import <GCDWebServer/GCDWebDAVServer.h>
#import <StylingKit/PXStylesheet.h>
#import <StylingKit/PXStylesheet-Private.h>

#import "Cloud.h"

@interface Cloud ()

@property(strong, nonatomic) GCDWebDAVServer* davServer;
@property(readonly, strong, nonatomic) NSString* defaultDavFolder;

@end

@implementation Cloud

@synthesize defaultDavFolder = _defaultDavFolder;

+ (instancetype)defaultCloud {
  static id instance;
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{
      instance = [[self alloc] init];
  });

  return instance;
}

- (GCDWebDAVServer*)davServer {
  if (!_davServer) {
    _davServer = [[GCDWebDAVServer alloc] initWithUploadDirectory:self.defaultDavFolder];
  }
  return _davServer;
}

- (NSString*)defaultDavFolder {
  if (!_defaultDavFolder) {
    _defaultDavFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask,
                                                             YES) firstObject];
  }
  return _defaultDavFolder;
}

- (void)startLocalServer {
  [self.davServer start];
  NSLog(@"Visit %@ in your WebDAV client", self.davServer.serverURL);

  [self prv_switchStylysheetToDocsFolder];
}

// TODO: Switch user.css to WebDAV folder as well
- (void)prv_switchStylysheetToDocsFolder {
  NSString* defaultPath = [[NSBundle mainBundle] pathForResource:kDefaultStylesheetName ofType:kStylesheetExt];

  NSString* davPath = [self.defaultDavFolder stringByAppendingPathComponent:defaultPath.lastPathComponent];

  if (![[NSFileManager defaultManager] fileExistsAtPath:davPath])
  {
    NSError *error;
    [[NSFileManager defaultManager] copyItemAtPath:defaultPath
                                            toPath:davPath
                                             error:&error];
    if (error)
    {
      DDLogError(@"Unable to copy %@ to %@ for the WebDAV sharing", defaultPath, davPath);
    }
  }

  if ([[NSFileManager defaultManager] fileExistsAtPath:davPath])
  {
    [PXStylesheet styleSheetFromFilePath:davPath withOrigin:PXStylesheetOriginApplication];
  }
}

@end

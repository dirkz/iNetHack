//
//  Hearse.h
//  iNetHack
//
//  Created by dirk on 10/7/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

//  This file is part of iNetHack.
//
//  iNetHack is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, version 2 of the License only.
//
//  iNetHack is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with iNetHack.  If not, see <http://www.gnu.org/licenses/>.

#import <Foundation/Foundation.h>

//#define HEARSE_ONLY  // run hearse without NetHack
//#define HEARSE_DISABLE // dont't run hearse at all

#define cHearseLogSize (4096)

#define kKeyHearse (@"hearse")
#define kKeyHearseUsername (@"hearseUsername")
#define kKeyHearseEmail (@"hearseEmail")
#define kKeyHearseId (@"hearseId")

@class FileLogger;

@interface Hearse : NSObject <UIAlertViewDelegate> {
	
	NSString *username;
	NSString *email;
	NSString *hearseId;
	NSThread *thread;
	NSString *clientVersionCrc;
	NSString *netHackVersion;
	NSString *netHackVersionCrc;
	NSString *hearseInternalVersion;
	
	BOOL deleteUploadedBones;
	
	int optimumNumberOfBonesDownloads;
	
	FileLogger *logger;
	
	int numberOfUploadedBones;
	int numberOfDownloadedBones;
	
}

@property (nonatomic, readonly) BOOL haveUploadedBones;

+ (Hearse *) instance;
+ (BOOL) start;
+ (void) stop;

+ (NSString *) md5HexForString:(NSString *)s;
+ (NSString *) md5HexForFile:(NSString *)filename;
+ (NSString *) md5HexForData:(NSData *)data;
+ (NSString *) md5HexForDigest:(const unsigned char *)digest;

+ (void) dumpDictionary:(NSDictionary *)dictionary;
+ (void) dumpResponse:(NSHTTPURLResponse *)response;
+ (void) dumpData:(NSData *)data;

@property (nonatomic, readonly, getter=isHearseReachable) BOOL hearseReachable;
- (void) start;
- (void) mainHearseLoop:(id)arg;
- (NSString *) urlForCommand:(NSString *)cmd;
- (NSMutableURLRequest *) requestForCommand:(NSString *)cmd;
- (NSHTTPURLResponse *) httpGetRequestWithoutData:(NSURLRequest *)req;
- (NSHTTPURLResponse *) httpPostRequestWithoutData:(NSMutableURLRequest *)req;
- (NSHTTPURLResponse *) httpGetRequest:(NSURLRequest *)req withData:(NSData **)data;

// header name is case insensitive!
- (NSString *) getHeader:(NSString *)header fromResponse:(NSHTTPURLResponse *)response;

- (NSString *) extractHearseErrorMessageFromResponse:(NSHTTPURLResponse *)response data:(NSData *)data;
- (NSString *) buildUserInfoCrc;
- (void) createNewUser;
- (BOOL) isValidBonesFileName:(NSString *)bonesFileName;
- (void) uploadBones;
- (void) uploadBonesFile:(NSString *)file;
- (void) downloadBones;
- (NSString *) downloadSingleBonesFileWithForce:(BOOL)force wasForced:(BOOL *)pForcedDownload;
- (NSArray *) existingBonesFiles;
- (void) alertUserWithError:(NSError *)error;
- (void) logHearseMessage:(NSString *)message;
- (void) logMessage:(NSString *)message;
- (void) logFormat:(NSString *)message, ...;

@end

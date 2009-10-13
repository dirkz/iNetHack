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

#define HEARSE_DEBUG (1)

#define kKeyHearse (@"hearse")
#define kKeyHearseUsername (@"hearseUsername")
#define kKeyHearseEmail (@"hearseEmail")
#define kKeyHearseId (@"hearseId")

@interface Hearse : NSObject <UIAlertViewDelegate> {
	
	NSString *username;
	NSString *email;
	NSString *hearseId;
	NSString *userInfoCrc;
	NSThread *thread;
	NSString *clientVersionCrc;
	NSMutableDictionary *uploads;
	NSString *netHackVersion;
	NSString *netHackVersionCrc;
	NSString *hearseInternalVersion;
	
	BOOL haveUploadedBones;
	NSString *hearseMessageOfTheDay;
	
}

+ (Hearse *) instance;
+ (BOOL) start;
+ (void) stop;

- (void) start;
- (void) mainHearseLoop:(id)arg;
- (void) dumpDictionary:(NSDictionary *)dictionary;
- (NSString *) md5HexForString:(NSString *)s;
- (NSString *) md5HexForFile:(NSString *)filename;
- (NSString *) md5HexForData:(NSData *)data;
- (NSString *) md5HexForDigest:(const unsigned char *)digest;
- (NSString *) urlForCommand:(NSString *)cmd;
- (NSMutableURLRequest *) requestForCommand:(NSString *)cmd;
- (NSHTTPURLResponse *) httpGetRequestWithoutData:(NSURLRequest *)req;
- (NSHTTPURLResponse *) httpPostRequestWithoutData:(NSMutableURLRequest *)req;

// header name is case insensitive!
- (NSString *) getHeader:(NSString *)header fromResponse:(NSHTTPURLResponse *)response;

- (void) dumpResponse:(NSHTTPURLResponse *)response;
- (NSString *) buildUserInfoCrc;
- (void) createNewUser;
- (void) changeUser;
- (void) uploadBones;
- (void) uploadBonesFile:(NSString *)file;
- (void) alertUserWithMessage:(NSString *)message;
- (void) alertUserWithError:(NSError *)error;

@end

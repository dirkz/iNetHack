//
//  Hearse.m
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

#import <CommonCrypto/CommonDigest.h>

#include <fcntl.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

#include "patchlevel.h"

#import "Hearse.h"
#import "NSString+Regexp.h"

static Hearse *_instance = nil;
static NSString *const hearseKeyUserInfoCrc = @"userInfoCrc";
static NSString *const hearseKeyLastUpload = @"lastUpload";
static NSString *const clientId = @"iNetHack Hearse";
static NSString *const clientVersion = @"iNetHack Hearse 1.3";

static NSString *const hearseBaseUrl = @"http://hearse.krollmark.com/bones.dll?act=";

// used URLs
static NSString *const hearseCommandNewUser = @"newuser";
static NSString *const hearseCommandChangeUserInfo = @"changeuserinfo";
static NSString *const hearseCommandUpload = @"upload";

@implementation Hearse

+ (Hearse *) instance {
	return _instance;
}

+ (void)load {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
					   hearseKeyLastUpload, [NSDate distantPast],
					   hearseKeyUserInfoCrc, @"",
					   nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:d];
	[pool drain];
}

+ (BOOL) start {
	BOOL enableHearse = [[NSUserDefaults standardUserDefaults] boolForKey:kKeyHearse];
	if (enableHearse) {
		_instance = [[self alloc] init];
		[_instance start];
	}
	return enableHearse;
}

+ (void) stop {
	[_instance release];
}

- (id) init {
	if (self = [super init]) {
		username = [[[NSUserDefaults standardUserDefaults] stringForKey:kKeyHearseUsername] copy];
		email = [[[NSUserDefaults standardUserDefaults] stringForKey:kKeyHearseEmail] copy];
		hearseId = [[[NSUserDefaults standardUserDefaults] stringForKey:kKeyHearseId] copy];
		NSLog(@"hearse %@ %@ %@", username, email, hearseId);
		lastUpload = [[[NSUserDefaults standardUserDefaults] objectForKey:hearseKeyLastUpload] copy];
		if (!lastUpload) {
			lastUpload = [[NSDate distantPast] copy];
		}
		userInfoCrc = [[[NSUserDefaults standardUserDefaults] objectForKey:hearseKeyUserInfoCrc] copy];
		clientVersionCrc = [[self md5HexForString:clientVersion] copy];
		netHackVersion = [[NSString stringWithFormat:@"%d,%d,%d,%d",
						  VERSION_MAJOR, VERSION_MINOR, PATCHLEVEL, EDITLEVEL] copy];
		netHackVersionCrc = [[self md5HexForString:netHackVersion] copy];
	}
	return self;
}

- (void) start {
	thread = [[NSThread alloc] initWithTarget:self selector:@selector(mainHearseLoop:) object:nil];
	[thread start];
}

- (void) mainHearseLoop:(id)arg {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
#if TARGET_IPHONE_SIMULATOR // sim only for now
	if (!hearseId || hearseId.length == 0) {
		if (email && email.length > 0) {
			[self createNewUser];
		}
	} else {
		NSString *changedUserInfoCrc = [[self buildUserInfoCrc] copy];
		if (![changedUserInfoCrc isEqual:userInfoCrc]) {
			[self changeUser];
		}
	}
	if (hearseId && hearseId.length > 0) {
		[self uploadBones];
	}
#endif
    [pool release];
}

#pragma mark md5 handling

- (NSString *) md5HexForString:(NSString *)s {
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	const char *data = [s cStringUsingEncoding:NSASCIIStringEncoding];
	CC_MD5(data, strlen(data), digest);
	return [self md5HexForDigest:digest];
}

- (NSString *) md5HexForFile:(NSString *)filename {
	CC_MD5_CTX context;
	CC_MD5_CTX *c = &context;
	CC_MD5_Init(c);
	int fh = open([filename cStringUsingEncoding:NSASCIIStringEncoding], O_RDONLY);
	if (fh != -1) {
		const int bufferSize = 1024;
		char buffer[bufferSize];
		int bytesRead;
		while ((bytesRead = read(fh, buffer, bufferSize))) {
			CC_MD5_Update(c, buffer, bytesRead);
		}
		close(fh);
		unsigned char digest[CC_MD5_DIGEST_LENGTH];
		CC_MD5_Final(digest, c);
		if (bytesRead == -1) {
			return nil;
		} else {
			return [self md5HexForDigest:digest];
		}
	} else {
		return nil;
	}
}

- (NSString *) md5HexForData:(NSData *)data {
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	CC_MD5([data bytes], data.length, digest);
	return [self md5HexForDigest:digest];
}

- (NSString *) md5HexForDigest:(const unsigned char *)digest {
	char md5[CC_MD5_DIGEST_LENGTH*2 + 1];
	char *pMd5 = md5;
	for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i) {
		sprintf(pMd5, "%02x", digest[i]);
		pMd5 += 2;
	}
	return [NSString stringWithCString:md5];
}

#pragma mark URL and connection handling

- (NSString *) urlForCommand:(NSString *)cmd {
	return [NSString stringWithFormat:@"%@%@", hearseBaseUrl, cmd];
}

- (NSMutableURLRequest *) requestForCommand:(NSString *)cmd {
	NSMutableURLRequest *theRequest=[NSMutableURLRequest
									 requestWithURL:[NSURL URLWithString:[self urlForCommand:cmd]]
									 cachePolicy:NSURLRequestReloadIgnoringCacheData
									 timeoutInterval:60.0];
	[theRequest addValue:clientVersionCrc forHTTPHeaderField:@"X_HEARSECRC"];
	[theRequest addValue:clientId forHTTPHeaderField:@"X_CLIENTID"];
	return theRequest;
}

- (NSHTTPURLResponse *) httpGetRequestWithoutData:(NSURLRequest *)req {
	NSURLResponse *response;
	NSError *error;
	NSData *received = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
	if (!received) {
		[self alertUser:[NSString stringWithFormat:@"Connection failed! Error - %@ %@",
						 [error localizedDescription],
						 [[error userInfo] objectForKey:NSErrorFailingURLStringKey]]];
		return nil;
	}
	return (NSHTTPURLResponse *) response;
}

- (NSHTTPURLResponse *) httpPostRequestWithoutData:(NSMutableURLRequest *)req {
	[req setHTTPMethod: @"POST"];
	return [self httpGetRequestWithoutData:req];
}

- (NSString *) getHeader:(NSString *)header fromResponse:(NSHTTPURLResponse *)response {
	NSDictionary *headers = [response allHeaderFields];
	for (NSString *key in [headers keyEnumerator]) {
		if ([key caseInsensitiveCompare:header] == NSOrderedSame) {
			return [headers objectForKey:key];
		}
	}
	return nil;
}

- (void) dumpResponse:(NSHTTPURLResponse *)response {
	NSDictionary *headers = [response allHeaderFields];
	for (NSString *key in [headers keyEnumerator]) {
		NSLog(@"%@ -> %@", key, [headers objectForKey:key]);
	}
}

#pragma mark hearse command implementation

- (NSString *) buildUserInfoCrc {
	return [self md5HexForString:[NSString stringWithFormat:@"%@ %@", username, email]];
}

- (void) createNewUser {
	NSMutableURLRequest *req = [self requestForCommand:hearseCommandNewUser];
	[req addValue:email forHTTPHeaderField:@"X_USEREMAIL"];
	if (username && username.length > 0) {
		[req addValue:username forHTTPHeaderField:@"X_USERNICK"];
	}
	NSHTTPURLResponse *response = [self httpGetRequestWithoutData:req];
	if (response) {
		NSString *headerHearseId = [self getHeader:@"X_USERTOKEN" fromResponse:response];
		if (headerHearseId) {
			hearseId = [headerHearseId copy];
		}
		if (hearseId && hearseId.length > 0) {
			userInfoCrc = [[self buildUserInfoCrc] copy];
			[[NSUserDefaults standardUserDefaults] setObject:hearseId forKey:kKeyHearseId];
			[[NSUserDefaults standardUserDefaults] setObject:userInfoCrc forKey:hearseKeyUserInfoCrc];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	}
}

- (void) changeUser {
	NSMutableURLRequest *req = [self requestForCommand:hearseCommandChangeUserInfo];
	[req addValue:hearseId forHTTPHeaderField:@"X_USERTOKEN"];
	[req addValue:email forHTTPHeaderField:@"X_USEREMAIL"];
	[req addValue:username forHTTPHeaderField:@"X_USERNICK"];
	NSHTTPURLResponse *response = [self httpGetRequestWithoutData:req];
	if (response) {
		userInfoCrc = [[self buildUserInfoCrc] copy];
		[[NSUserDefaults standardUserDefaults] setObject:userInfoCrc forKey:hearseKeyUserInfoCrc];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (void) uploadBones {
	NSFileManager *filemanager = [NSFileManager defaultManager];
	NSArray *filelist = [filemanager directoryContentsAtPath:@"."];
	for (NSString *filename in filelist) {
		if ([filename startsWithString:@"bon"]) {
			NSDictionary *fileAttributes = [filemanager fileAttributesAtPath:filename traverseLink:NO];
			NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];
			if (fileModDate) {
				NSComparisonResult cmp = [fileModDate compare:lastUpload];
				if (cmp == NSOrderedDescending) {
					[self uploadBonesFile:filename];
				}
			}
		}
	}
	//lastUpload = [[NSDate date] copy];
	//[[NSUserDefaults standardUserDefaults] setObject:lastUpload forKey:hearseKeyLastUpload];
}

- (void) uploadBonesFile:(NSString *)file {
	NSMutableURLRequest *req = [self requestForCommand:hearseCommandUpload];
	[req addValue:netHackVersionCrc forHTTPHeaderField:@"X_VERSIONCRC"];
	[req addValue:hearseId forHTTPHeaderField:@"X_USERTOKEN"];
	[req addValue:[file lastPathComponent] forHTTPHeaderField:@"X_FILENAME"];
	if (!haveUploadedBones) {
		[req addValue:@"Y" forHTTPHeaderField:@"X_WANTSINFO"];
	}
	NSData *data = [NSData dataWithContentsOfFile:file];
	[req setHTTPBody:data];
	[req addValue:[self md5HexForData:data] forHTTPHeaderField:@"X_BONESCRC"];
	NSHTTPURLResponse *response = [self httpPostRequestWithoutData:req];
	if (response) {
		[self dumpResponse:response];
		hearseMessageOfTheDay = [[self getHeader:@"X_MOTD" fromResponse:response] copy];
		hearseInternalVersion = [[self getHeader:@"X_NETHACKVER" fromResponse:response] copy];
		if (hearseMessageOfTheDay) {
			[self alertUser:hearseMessageOfTheDay];
		}
	}
	//haveUploadedBones = YES;
}

#pragma mark UI

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
}

- (void) alertUserOnUIThread:(NSString *)message {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hearse" message:message
												   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}

- (void) alertUser:(NSString *)message {
	//[self performSelectorOnMainThread:@selector(alertUserOnUIThread:) withObject:message waitUntilDone:YES];
	NSLog(message);
}

- (void) dealloc {
	[username release];
	[email release];
	[hearseId release];
	[thread release];
	[clientVersionCrc release];
	[super dealloc];
}

@end

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
#import <SystemConfiguration/SystemConfiguration.h>

#include <fcntl.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

#include "patchlevel.h"

#import "Hearse.h"
#import "NSString+Regexp.h"
#import "HearseFileRegistry.h"
#import "FileLogger.h"

static Hearse *instance = nil;

static NSString *const clientId = @"iNetHack Hearse";
static NSString *const clientVersion = @"iNetHack Hearse 1.3";

static NSString *const hearseHost = @"hearse.krollmark.com";
static NSString *const hearseBaseUrl = @"http://hearse.krollmark.com/bones.dll?act=";

// hearse commands
static NSString *const hearseCommandNewUser = @"newuser";
static NSString *const hearseCommandUpload = @"upload";
static NSString *const hearseCommandDownload = @"download";
static NSString *const hearseCommandBonesCheck = @"bonescheck";

@implementation Hearse

+ (Hearse *) instance {
	return instance;
}

+ (BOOL) start {
	BOOL enableHearse = [[NSUserDefaults standardUserDefaults] boolForKey:kKeyHearse];
	if (enableHearse) {
		instance = [[self alloc] init];
		[instance start];
	}
	return enableHearse;
}

+ (void) stop {
	[instance release];
}

#pragma mark md5 handling

+ (NSString *) md5HexForString:(NSString *)s {
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	const char *data = [s cStringUsingEncoding:NSASCIIStringEncoding];
	CC_MD5(data, strlen(data), digest);
	return [self md5HexForDigest:digest];
}

+ (NSString *) md5HexForFile:(NSString *)filename {
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

+ (NSString *) md5HexForData:(NSData *)data {
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	CC_MD5([data bytes], data.length, digest);
	return [self md5HexForDigest:digest];
}

+ (NSString *) md5HexForDigest:(const unsigned char *)digest {
	char md5[CC_MD5_DIGEST_LENGTH*2 + 1];
	char *pMd5 = md5;
	for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i) {
		sprintf(pMd5, "%02x", digest[i]);
		pMd5 += 2;
	}
	return [NSString stringWithCString:md5 encoding:NSASCIIStringEncoding];
}

#pragma mark other static helpers

+ (void) dumpDictionary:(NSDictionary *)dictionary {
	for (NSString *key in [dictionary keyEnumerator]) {
		NSLog(@"%@ -> %@", key, [dictionary objectForKey:key]);
	}
}

+ (void) dumpResponse:(NSHTTPURLResponse *)response {
	NSDictionary *headers = [response allHeaderFields];
	for (NSString *key in [headers keyEnumerator]) {
		NSLog(@"%@ -> %@", key, [headers objectForKey:key]);
	}
}

+ (void) dumpData:(NSData *)data {
	NSString *s = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
}

#pragma mark constructors, main loop

- (id) init {
	if (self = [super init]) {
		[[HearseFileRegistry alloc] init];
		username = [[[NSUserDefaults standardUserDefaults] stringForKey:kKeyHearseUsername] copy];
		email = [[[NSUserDefaults standardUserDefaults] stringForKey:kKeyHearseEmail] copy];
		hearseId = [[[NSUserDefaults standardUserDefaults] stringForKey:kKeyHearseId] copy];
		clientVersionCrc = [[Hearse md5HexForString:clientVersion] copy];
		netHackVersion = [[NSString stringWithFormat:@"%d,%d,%d,%d",
						  VERSION_MAJOR, VERSION_MINOR, PATCHLEVEL, EDITLEVEL] copy];
		netHackVersionCrc = [[Hearse md5HexForString:netHackVersion] copy];
		deleteUploadedBones = YES;
		hearseInternalVersion = [@"43" copy]; // will be changed in uploadBonesFile:
		optimumNumberOfBonesDownloads = 2; // always want to download 2 bones
		
		logger = [[FileLogger alloc] initWithFile:@"hearse.log" maxSize:cHearseLogSize];
	}
	return self;
}

- (BOOL) isHearseReachable {
	SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [hearseHost UTF8String]);
	if (reachabilityRef != NULL) {
		SCNetworkReachabilityFlags flags;
		Boolean valid = SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
		CFRelease(reachabilityRef);
		if (!valid) {
			return NO;
		}
		return flags & kSCNetworkReachabilityFlagsReachable;
	}
	return NO;
}

- (void) start {
	thread = [[NSThread alloc] initWithTarget:self selector:@selector(mainHearseLoop:) object:nil];
	[thread start];
}

- (void) mainHearseLoop:(id)arg {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	if ([self isHearseReachable]) {
		if (!hearseId || hearseId.length == 0) {
			if (email && email.length > 0) {
				[self createNewUser];
			}
		} else {
			[self logFormat:@"using existing token %@", hearseId];
		}

		if (hearseId && hearseId.length > 0) {
			[self uploadBones];
			[self downloadBones];
		}
	}
	[logger flush];
	[pool drain];
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
	return [self httpGetRequest:req withData:nil];
}

- (NSHTTPURLResponse *) httpPostRequestWithoutData:(NSMutableURLRequest *)req {
	[req setHTTPMethod: @"POST"];
	return [self httpGetRequestWithoutData:req];
}

- (NSHTTPURLResponse *) httpGetRequest:(NSURLRequest *)req withData:(NSData **)data {
	NSURLResponse *response;
	NSError *error;
	NSData *received = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
	if (data) {
		*data = received;
	}
	if (!received) {
		[self logMessage:[NSString stringWithFormat:@"Connection failed! Error - %@ %@",
									[error localizedDescription],
									[[error userInfo] objectForKey:NSErrorFailingURLStringKey]]];
		return nil;
	}
	return (NSHTTPURLResponse *) response;
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

- (NSString *) extractHearseErrorMessageFromResponse:(NSHTTPURLResponse *)response data:(NSData *)data {
	NSString *fatal = [self getHeader:@"FATAL" fromResponse:response];
	if (fatal) {
		return fatal;
	} else {
		fatal = [self getHeader:@"X_error" fromResponse:response];
		if (fatal) {
			return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
		}
	}
	return nil;
}

#pragma mark hearse command implementation

- (NSString *) buildUserInfoCrc {
	return [Hearse md5HexForString:[NSString stringWithFormat:@"%@ %@", username, email]];
}

- (void) createNewUser {
	NSMutableURLRequest *req = [self requestForCommand:hearseCommandNewUser];
	[req addValue:email forHTTPHeaderField:@"X_USERTOKEN"];
	if (username && username.length > 0) {
		[req addValue:username forHTTPHeaderField:@"X_USERNICK"];
	}
	NSData *data = nil;
	NSHTTPURLResponse *response = [self httpGetRequest:req withData:&data];
	if (response) {
		NSString *errorMessage = [self extractHearseErrorMessageFromResponse:response data:data];
		if (errorMessage) {
			[self logMessage:errorMessage];
		} else {
			NSString *headerHearseId = [self getHeader:@"X_USERTOKEN" fromResponse:response];
			if (headerHearseId) {
				[hearseId release];
				hearseId = [headerHearseId copy];
			}
			if (hearseId && hearseId.length > 0) {
				[[NSUserDefaults standardUserDefaults] setObject:hearseId forKey:kKeyHearseId];
				[[NSUserDefaults standardUserDefaults] synchronize];
				[self logFormat:@"created user %@ with token %@", email, hearseId];
			}
		}
	}
}

- (BOOL) isValidBonesFileName:(NSString *)bonesFileName {
	return !([bonesFileName containsString:@"D0.1"] ||
			 [bonesFileName containsString:@"D0.2"] ||
			 [bonesFileName containsString:@"D0.3"]);
}

- (void) uploadBones {
	// never ever upload bones from the simulator!
#if !TARGET_IPHONE_SIMULATOR
	NSFileManager *filemanager = [NSFileManager defaultManager];
	NSArray *filelist = [filemanager directoryContentsAtPath:@"."];
	for (NSString *filename in filelist) {
		if ([filename startsWithString:@"bon"] && [self isValidBonesFileName:filename]) {
			if (![[HearseFileRegistry instance] haveDownloadedFile:filename]) {
				[self uploadBonesFile:filename];
			}
		}
	}
#endif
}

- (void) uploadBonesFile:(NSString *)file {
	NSMutableURLRequest *req = [self requestForCommand:hearseCommandUpload];
	[req addValue:netHackVersionCrc forHTTPHeaderField:@"X_VERSIONCRC"];
	[req addValue:hearseId forHTTPHeaderField:@"X_USERTOKEN"];
	[req addValue:[file lastPathComponent] forHTTPHeaderField:@"X_FILENAME"];
	if (!self.haveUploadedBones) {
		[req addValue:@"Y" forHTTPHeaderField:@"X_WANTSINFO"];
	}
	NSData *data = [NSData dataWithContentsOfFile:file];
	[req setHTTPBody:data];
	[req addValue:[Hearse md5HexForData:data] forHTTPHeaderField:@"X_BONESCRC"];
	NSHTTPURLResponse *response = [self httpPostRequestWithoutData:req];
	if (response) {
		NSString *hearseMessageOfTheDay = [self getHeader:@"X_MOTD" fromResponse:response];
		NSString *version = [self getHeader:@"X_NETHACKVER" fromResponse:response];
		if (version && ![version isEqual:hearseInternalVersion]) {
			[hearseInternalVersion release];
			hearseInternalVersion = [version copy];
		}
		if (hearseMessageOfTheDay) {
			[self logMessage:hearseMessageOfTheDay];
		}
		if (deleteUploadedBones) {
			NSError *error = nil;
			[[NSFileManager defaultManager] removeItemAtPath:file error:&error];
			if (error) {
				[self alertUserWithError:error];
			}
		}
		numberOfUploadedBones++;
		[self logFormat:@"uploaded file %@", file];
	}
}

- (BOOL) haveUploadedBones {
	return numberOfUploadedBones > 0;
}

- (void) downloadBones {
	NSString *message = nil;
	BOOL forcedDownload = NO;
	while (!message) {
		message = [self downloadSingleBonesFileWithForce:NO wasForced:&forcedDownload];
		if (!message) {
			numberOfDownloadedBones++;
		}
	}
	[self logHearseMessage:message];
	if (numberOfDownloadedBones < optimumNumberOfBonesDownloads) {
		// force downloads
		message = nil;
		forcedDownload = NO;
		while (!message && numberOfDownloadedBones < optimumNumberOfBonesDownloads) {
			message = [self downloadSingleBonesFileWithForce:YES wasForced:&forcedDownload];
			if (!message) {
				numberOfDownloadedBones++;
			}
		}
		[self logHearseMessage:message];
	}
}

- (NSString *) downloadSingleBonesFileWithForce:(BOOL)force wasForced:(BOOL *)pForcedDownload {
	NSString *existingBonesFiles = [[self existingBonesFiles] componentsJoinedByString:@","];
	NSMutableURLRequest *req = [self requestForCommand:hearseCommandDownload];
	[req addValue:hearseId forHTTPHeaderField:@"X_USERTOKEN"];
	[req addValue:existingBonesFiles forHTTPHeaderField:@"X_USERLEVELS"];
	[req addValue:hearseInternalVersion forHTTPHeaderField:@"X_NETHACKVER"];
	if (force) {
		[req addValue:@"Y" forHTTPHeaderField:@"X_FORCEDOWNLOAD"];
	}
	NSData *data = nil;
	NSHTTPURLResponse *response = [self httpGetRequest:req withData:&data];
	if (response) {
		NSString *forceDownloadResponse = [self getHeader:@"X_FORCEDOWNLOAD" fromResponse:response];
		BOOL forceDownload = forceDownloadResponse && ([forceDownloadResponse isEqual:@"Y"] ||
													   [forceDownloadResponse isEqual:@"y"]);
		if (pForcedDownload) {
			*pForcedDownload = forceDownload;
		}
		NSString *errorMessage = [self extractHearseErrorMessageFromResponse:response data:data];
		if (errorMessage) {
			return errorMessage;
		} else {
			NSString *filename = [self getHeader:@"X_FILENAME" fromResponse:response];
			NSString *md5 = [self getHeader:@"X_BONESCRC" fromResponse:response];
			if (!forceDownload) {
				if (filename) {
					NSString *myMd5 = [Hearse md5HexForData:data];
					if (![md5 isEqual:myMd5]) {
						return [NSString stringWithFormat:@"Mismatched md5 for downloaded file %@", filename];
					} else {
						[data writeToFile:filename atomically:YES];
						[[HearseFileRegistry instance] registerDownloadedFile:filename withMd5:myMd5];
						[self logFormat:@"downloaded file %@", filename];
					}
				} else {
					return @"Missing filename from hearse";
				}
			} else {
				return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
			}
		}
	} else {
		return @"No response from hearse server";
	}
	return nil;
}

- (NSArray *) existingBonesFiles {
	NSMutableArray *bones = [NSMutableArray array];
	NSFileManager *filemanager = [NSFileManager defaultManager];
	NSArray *filelist = [filemanager directoryContentsAtPath:@"."];
	for (NSString *filename in filelist) {
		if ([filename startsWithString:@"bon"]) {
			[bones addObject:filename];
		}
	}
	return bones;
}

#pragma mark UI

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
}

- (void) alertUserOnUIThreadWithMessage:(NSString *)message {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hearse" message:message
												   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}

- (void) alertUserWithError:(NSError *)error {
	NSString *message = [NSString stringWithFormat:@"Error - %@", [error localizedDescription]];
	[self performSelectorOnMainThread:@selector(alertUserOnUIThreadWithMessage:) withObject:message waitUntilDone:YES];
}

- (void) logHearseMessage:(NSString *)message {
	NSString *msg = message;
	if (message) {
		NSRange newLineRange = [message rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
		if (newLineRange.location != NSNotFound) {
			msg = [message substringToIndex:newLineRange.location];
		}
	}
	[self logMessage:msg];
}

- (void) logMessage:(NSString *)message {
	if (message) {
		NSLogv(message, NULL);
		[logger logString:message];
	}
}

- (void) logFormat:(NSString *)message, ... {
	va_list vlist;
	va_start(vlist, message);
	NSString *s = [[NSString alloc] initWithFormat:message arguments:vlist];
	[self logMessage:s];
	[s release];
}

- (void) dealloc {
	[username release];
	[email release];
	[hearseId release];
	[clientVersionCrc release];
	[netHackVersion release];
	[netHackVersionCrc release];
	[thread release];
	[hearseInternalVersion release];
	[[HearseFileRegistry instance] release];
	[logger release];
	[super dealloc];
}

@end

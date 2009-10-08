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
#import "Hearse.h"

static NSString *version = @"iNetHack Hearse 1.3";
static Hearse *_instance = nil;

@implementation Hearse

+ (Hearse *) instance {
	return _instance;
}

+ (BOOL) start {
	BOOL enableHearse = [[NSUserDefaults standardUserDefaults] boolForKey:kKeyHearse];
	if (enableHearse) {
		_instance = [[self alloc] init];
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
		thread = [[NSThread alloc] initWithTarget:self selector:@selector(mainHearseLoop:) object:nil];
		crc = [self md5HexForString:version];
		NSString *md5 = [self md5HexForFile:@"bonD0.1"];
		NSLog(@"md5 %@", md5);
		[thread start];
	}
	return self;
}

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

- (NSString *) md5HexForDigest:(const unsigned char *)digest {
	char md5[CC_MD5_DIGEST_LENGTH*2 + 1];
	char *pMd5 = md5;
	for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i) {
		sprintf(pMd5, "%02x", digest[i]);
		pMd5 += 2;
	}
	return [NSString stringWithCString:md5];
}

- (void) mainHearseLoop:(id)arg {
#if TARGET_IPHONE_SIMULATOR // sim only for now
	if (!hearseId || hearseId.length == 0) {
		if (email && email.length > 0) {
		}
	}
#endif
}

- (void) dealloc {
	[username release];
	[email release];
	[hearseId release];
	[thread release];
	[crc release];
	[super dealloc];
}

@end

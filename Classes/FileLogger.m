//
//  FileLogger.m
//  iNetHack
//
//  Created by dirk on 11/25/09.
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

#include <fcntl.h>

#import "FileLogger.h"

@implementation FileLogger

+ (int) openTmpFile {
	NSString *template = [NSTemporaryDirectory() stringByAppendingPathComponent:@"log.tmp.XXXX"];
	int n = template.length+1;
	char str[n];
	[template getCString:str maxLength:n encoding:NSASCIIStringEncoding];
	return mkstemp(str);
}

+ (NSString *) tmpFileName {
	NSString *template = [NSTemporaryDirectory() stringByAppendingPathComponent:@"log.tmp.XXXX"];
	int n = template.length+1;
	char str[n];
	[template getCString:str maxLength:n encoding:NSASCIIStringEncoding];
	char *pStr = mktemp(str);
	return [NSString stringWithCString:pStr encoding:NSASCIIStringEncoding];
}

- (void) resize {
	NSDictionary *info = [[NSFileManager defaultManager] attributesOfItemAtPath:filename error:NULL];
	if (info) {
		unsigned long size = [info fileSize];
		if (size >= maxSize) {
			int halfSize = maxSize / 2;
			NSData *src = [[NSData alloc] initWithContentsOfMappedFile:filename];
			NSData *sub = [src subdataWithRange:NSMakeRange(size - halfSize, halfSize)];
			[src release];
			const char *bytes = [sub bytes];
			const char *pBytes = bytes;
			int offset = 0;
			while (*pBytes++ != '\n') {
				offset++;
			}
			offset++;
			NSData *newData = [sub subdataWithRange:NSMakeRange(offset, sub.length - offset)];
			[sub release];
			[newData writeToFile:filename atomically:NO];
			[newData release];
		}
	}
}

- (id) initWithFile:(NSString *)path maxSize:(int)ms {
	if (self = [super init]) {
		filename = [path copy];
		maxSize = ms;
		[self resize];
		fd = fopen([filename cStringUsingEncoding:NSASCIIStringEncoding], "a");
	}
	return self;
}

- (id) initWithFile:(NSString *)path {
	return [self initWithFile:path maxSize:4096];
}

- (void) logString:(NSString *)message {
	int n = message.length + 2;
	char msg[n];
	[message getCString:msg maxLength:n encoding:NSASCIIStringEncoding];
	msg[n-2] = '\n';
	msg[n-1] = 0;
	fputs(msg, fd);
}

- (void) dealloc {
	fclose(fd);
	[filename release];
	[super dealloc];
}

@end

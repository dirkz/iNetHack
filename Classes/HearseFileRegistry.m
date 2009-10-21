//
//  HearseFileRegistry.m
//  iNetHack
//
//  Created by dirk on 10/21/09.
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

#import "HearseFileRegistry.h"
#import "Hearse.h"

static NSString *const hearseFileRegistryKey = @"hearseFileRegistryKey";
static NSString *const hearseFileRegistryKeyUploads = @"hearseFileRegistryKeyUploads";
static NSString *const hearseFileRegistryKeyDownloads = @"hearseFileRegistryKeyDownloads";

static HearseFileRegistry *_instance;

@implementation HearseFileRegistry

+ (void)load {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	NSDictionary *registry = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSDictionary dictionary], hearseFileRegistryKeyUploads,
							  [NSDictionary dictionary], hearseFileRegistryKeyDownloads,
							  nil];
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
					   registry, hearseFileRegistryKey,
					   nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:d];
	[pool drain];
}

+ (HearseFileRegistry *) instance {
	return _instance;
}

- (id) init {
	if (self = [super init]) {
		NSDictionary *registry = [[NSUserDefaults standardUserDefaults] objectForKey:hearseFileRegistryKey];
		uploads = [[NSMutableDictionary alloc] initWithDictionary:[registry objectForKey:hearseFileRegistryKeyUploads]];
		downloads = [[NSMutableDictionary alloc] initWithDictionary:[registry objectForKey:hearseFileRegistryKeyDownloads]];
	}
	[Hearse dumpDictionary:downloads];
	_instance = self;
	return self;
}

- (void) synchronize {
	NSDictionary *registry = [NSDictionary dictionaryWithObjectsAndKeys:
							  uploads, hearseFileRegistryKeyUploads,
							  downloads, hearseFileRegistryKeyDownloads,
							  nil];
	[[NSUserDefaults standardUserDefaults] setObject:registry forKey:hearseFileRegistryKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) registerDownloadedFile:(NSString *)filename {
	NSString *md5 = [Hearse md5HexForFile:filename];
	NSString *file = [filename lastPathComponent];
	[downloads setObject:md5 forKey:file];
	[self synchronize];
}

- (BOOL) haveDownloadedFile:(NSString *)filename {
	NSString *file = [filename lastPathComponent];
	NSString *md5 = [downloads objectForKey:file];
	if (md5) {
		NSString *actualMd5 = [Hearse md5HexForFile:filename];
		return [md5 isEqual:actualMd5];
	} else {
		return NO;
	}
}
		
- (void) dealloc {
	[uploads release];
	[downloads release];
	[super dealloc];
}

@end

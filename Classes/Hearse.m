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

#import "Hearse.h"

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
		[thread start];
	}
	return self;
}

- (void) mainHearseLoop:(id)arg {
	if (!hearseId || hearseId.length == 0) {
		if (email && email.length > 0) {
		}
	}
}

- (void) dealloc {
	[username release];
	[email release];
	[hearseId release];
	[thread release];
	[super dealloc];
}

@end

//
//  Shortcut.m
//  iNetHack
//
//  Created by dirk on 7/14/09.
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

#import "Shortcut.h"
#import "MainViewController.h"
#import "NethackEventQueue.h"

static NSString* ParseShortcutString (NSString* keys) {
	if ([keys characterAtIndex:0] == '^') {
		keys = [NSString stringWithFormat:@"%c", (0x1f & [keys characterAtIndex:1])];
	}
	return keys;
}

@implementation Shortcut

@synthesize title;

- (id) initWithTitle:(NSString *)t keys:(NSString *)k selector:(SEL)s target:(id)tar {
	if (self = [super init]) {
		title = [t retain];
		keys = [ParseShortcutString(k) retain];
		selector = s;
		target = [tar retain];
	}
	return self;
}

- (id) initWithTitle:(NSString *)t keys:(NSString *)k {
	return [self initWithTitle:t keys:k selector:NULL target:nil];
}

- (char) key {
	return [keys characterAtIndex:0];
}

- (void) invoke:(id)sender {
	if (selector) {
		[[UIApplication sharedApplication] sendAction:selector to:target from:sender forEvent:nil];
	} else {
		NethackEventQueue *q = [[MainViewController instance] nethackEventQueue];
		for (int i = 0; i < keys.length; ++i) {
			[q addKeyEvent:[keys characterAtIndex:i]];
		}
	}
}

- (void) dealloc {
	[title release];
	[keys release];
	[target release];
	[super dealloc];
}

@end

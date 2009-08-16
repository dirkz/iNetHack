//
//  MenuItem.m
//  iNetHack
//
//  Created by dirk on 6/29/09.
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

#import "MenuItem.h"

@implementation MenuItem

@synthesize title, accessory, children, key, tag;

+ (id) menuItemWithTitle:(NSString *)n target:(id)t selector:(SEL)s accessory:(BOOL)a {
	return [[[self alloc] initWithTitle:n target:t selector:s accessory:a] autorelease];
}

+ (id) menuItemWithTitle:(NSString *)n children:(NSArray *)ch {
	return [[[self alloc] initWithTitle:n children:ch] autorelease];
}

+ (id) menuItemWithTitle:(NSString *)n key:(char)k accessory:(BOOL)a {
	return [[[self alloc] initWithTitle:n key:k accessory:a] autorelease];
}

+ (id) menuItemWithTitle:(NSString *)n key:(char)k {
	return [[[self alloc] initWithTitle:n key:k] autorelease];
}

- (id) initWithTitle:(NSString *)n target:(id)t selector:(SEL)s accessory:(BOOL)a {
	if (self = [super init]) {
		title = [n retain];
		selector = s;
		target = [t retain];
		accessory = a;
	}
	return self;
}

- (id) initWithTitle:(NSString *)n children:(NSArray *)ch {
	if (self = [self initWithTitle:n target:nil selector:NULL accessory:YES]) {
		self.children = ch;
	}
	return self;
}

- (id) initWithTitle:(NSString *)n key:(char)k accessory:(BOOL)a {
	if (self = [self initWithTitle:n target:nil selector:NULL accessory:YES]) {
		key = k;
		accessory = a;
	}
	return self;
}

- (id) initWithTitle:(NSString *)n key:(char)k {
	return [self initWithTitle:n key:k accessory:NO];
}

- (void) invoke {
	[target performSelector:selector withObject:self];
}

- (void) dealloc {
	[title release];
	[target release];
	[children release];
	[super dealloc];
}

@end

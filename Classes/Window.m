//
//  Window.m
//  iNetHack
//
//  Created by dirk on 6/26/09.
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

#import "Window.h"
#import "NethackMenuItem.h"
#import "NSString+Regexp.h"

@implementation Window

@synthesize type, curx, cury, width, height, strings, menuItems, menuPrompt, isShallowMenu, menuHow, menuList, menuResult, log;
@synthesize acceptBareHanded, acceptMore, acceptMoney;

- (id) initWithType:(winid)t {
	if (self = [super init]) {
		type = t;
		maxWidth = COLNO;
		maxHeight = ROWNO;
		switch (t) {
			case NHW_MESSAGE:
				width = maxWidth;
				height = 3;
				break;
			case NHW_STATUS:
				width = maxWidth;
				height = 1;
				break;
			case NHW_MAP:
				width = maxWidth;
				height = maxHeight;
				break;
			case NHW_MENU:
			case NHW_TEXT:
				width = maxWidth;
				height = maxHeight;
				break;
			default:
				break;
		}
		
		size_t n = sizeof(glyphs[0]) * width * height;
		glyphs = malloc(n);
		memset(glyphs, kNoGlyph, n);
		strings = [[NSMutableArray alloc] init];
		maxLogEntries = 50;
		log = [[NSMutableArray alloc] init];
	}
	return self;
}

- (int) glyphAtX:(int)x y:(int)y {
	return glyphs[width * y + x];
}

- (void) setGlyph:(int)g atX:(int)x y:(int)y {
	glyphs[width * y + x] = g;
}

- (void) clear {
	for (int j = 0; j < height; ++j) {
		for (int i = 0; i < width; ++i) {
			[self setGlyph:kNoGlyph atX:i y:j];
		}
	}
	[strings removeAllObjects];
}

- (void) putString:(const char *)s {
	NSString *str = [NSString stringWithCString:s];
	if (type == NHW_STATUS && strings.count == 2) {
		[strings removeAllObjects];
	}
	if (type == NHW_STATUS) {
		str = [str stringWithTrimmedWhitespaces];
	}
	[strings addObject:str];
	[self addLogString:str];
}

- (NSString *) text {
	NSString *result = [NSString string];
	for (NSString *s in strings) {
		if (result.length > 0) {
			result = [result stringByAppendingFormat:@"\n%@", s];
		} else {
			result = [result stringByAppendingFormat:@"%@", s];
		}
	}
	return result;
}

- (void) startMenu {
	[menuItems release];
	menuItems = [[NSMutableArray alloc] init];
}

- (void) addMenuItem:(NethackMenuItem *)item {
	if (menuItems.count == 0) {
		if (item.isTitle) {
			isShallowMenu = NO;
		} else {
			isShallowMenu = YES;
		}
		[menuItems addObject:item];
	} else if (isShallowMenu) {
		[menuItems addObject:item];
	} else {
		if (item.isTitle) {
			[menuItems addObject:item];
		} else {
			NethackMenuItem *lastItem = [menuItems lastObject];
			[lastItem.children addObject:item];
		}
	}
}

- (void) addLogString:(NSString *)s {
	if (type != NHW_STATUS) {
		[log addObject:s];
		if (log.count > maxLogEntries) {
			[log removeObjectAtIndex:0];
		}
	}
}

- (void) clearMessages {
	[strings removeAllObjects];
}

- (void) dealloc {
	free(glyphs);
	[strings release];
	[log release];
	[menuItems release];
	[super dealloc];
}

@end

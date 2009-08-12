//
//  ShortcutView.m
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

#import "ShortcutView.h"
#import "Shortcut.h"
#import "MainViewController.h"
#import "TouchInfo.h"
#import "TouchInfoStore.h"

static NSArray* DefaultShortcuts (id target) {
	// Add shortcut bar items here
	// The first field is the title, the second is the method selector to perform
	// If the selector is NULL then the title will be treated as a key sequence
	static struct { NSString *const title; const char *action; } const defaultShortcuts[] = {
		// Page 1
		{ @".",    NULL,            },   { @"20s",  NULL,            },
		{ @":",    NULL,            },   { @"99.",  NULL,            },
		{ @";",    NULL,            },   { @"#",    NULL,            },
		{ @"abc",  "showKeyboard:", },   { @"menu", "showMainMenu:", },
		// Page 2
		{ @"i",    NULL,            },   { @"e",    NULL,            },
		{ @"t",    NULL,            },   { @"f",    NULL,            },
		{ @"z",    NULL,            },   { @"Z",    NULL,            },
		{ @"a",    NULL,            },   { @"^d",   NULL,            },
		// Page 3
		{ @"^a",   NULL,            },   { @"r",    NULL,            },
		{ @"q",    NULL,            },   { @"E",    NULL,            },
		{ @"Q",    NULL,            },   { @"d",    NULL,            },
		{ @"D",    NULL,            },   { @"w",    NULL,            },
		// Page 4
		{ @"W",    NULL,            },   { @"P",    NULL,            },
		{ @"T",    NULL,            },   { @"A",    NULL,            },
		{ @"p",    NULL,            },   { @"^x",   NULL             },
	};

	NSUInteger const shortcutsCount = sizeof(defaultShortcuts) / sizeof(defaultShortcuts[0]);
	NSMutableArray *shortcuts = [NSMutableArray arrayWithCapacity:shortcutsCount];
	for (NSUInteger i = 0; i < shortcutsCount; ++i) {
		NSString *keys = (defaultShortcuts[i].action ? nil : defaultShortcuts[i].title);
		Shortcut *shortcut = [[Shortcut alloc] initWithTitle:defaultShortcuts[i].title keys:keys selector:sel_getUid(defaultShortcuts[i].action) target:target arg:nil];
		[shortcuts addObject:shortcut];
		[shortcut release];
	}
	return shortcuts;
}

@implementation ShortcutView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		self.clearsContextBeforeDrawing = YES;
		recentlyTouchedItem = -1;
		font = [UIFont boldSystemFontOfSize:12];
		tileSize = CGSizeMake(40,40);
		touchInfoStore = [[TouchInfoStore alloc] init];
		shortcuts = [DefaultShortcuts(self) retain];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
	maxShortcutsOnScreen = size.width / tileSize.width;
	CGSize s = CGSizeMake(tileSize.width * maxShortcutsOnScreen, tileSize.height);
	return s;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	float white[] = {1,1,1,1};
	float grey[] = {0.5f,0.5f,0.5f,1};
	float green[] = {0,1,0,1};
	CGContextSetStrokeColor(ctx, white);
	CGContextSetFillColor(ctx, white);
	CGPoint current = CGPointMake(0,0);
	for (int i = 0; i < maxShortcutsOnScreen; ++i) {
		float pad = 2.0f;
		float halfPad = pad/2;
		CGRect r = CGRectMake(current.x+halfPad, current.y+halfPad, tileSize.width-pad, tileSize.height-pad);
		if (i+currentIndex == recentlyTouchedItem && i+currentIndex < shortcuts.count) {
			CGContextSetFillColor(ctx, green);
		} else {
			CGContextSetFillColor(ctx, grey);
		}
		CGContextFillRect(ctx, r);
		CGContextSetFillColor(ctx, white);
		if (i+currentIndex < shortcuts.count) {
			Shortcut *sh = [shortcuts objectAtIndex:i+currentIndex];
			CGSize stringSize = [sh.title sizeWithFont:font];
			CGPoint p = current;
			p.x += (tileSize.width-stringSize.width) / 2;
			p.y += (tileSize.height-stringSize.height) / 2;
			[sh.title drawAtPoint:p withFont:font];
		}
		current.x += tileSize.width;
	}
}

#pragma mark ad-hoc methods for shortcuts

- (void) showMainMenu:(id)obj {
	[[MainViewController instance] showMainMenu:obj];
}

- (void) showKeyboard:(id)obj {
	[[MainViewController instance] nethackKeyboard:obj];
}

#pragma mark touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[touchInfoStore storeTouches:touches];
	UITouch *touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];
	int i = floor(p.x/tileSize.width);
	i += currentIndex;
	if (i < maxShortcutsOnScreen+currentIndex) {
		recentlyTouchedItem = i;
		[self setNeedsDisplay];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	recentlyTouchedItem = -1;
	[self setNeedsDisplay];
	[touchInfoStore removeTouches:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (touches.count == 1) {
		UITouch *touch = [touches anyObject];
		TouchInfo *ti = [touchInfoStore touchInfoForTouch:touch];
		if (!ti.pinched) {
			CGPoint p = [touch locationInView:self];
			CGPoint delta = CGPointMake(p.x-ti.initialLocation.x, p.y-ti.initialLocation.y);
			BOOL move = NO;
			if (!ti.moved && (abs(delta.x)+abs(delta.y) > 10)) {
				ti.moved = YES;
				move = YES;
			} else if (ti.moved) {
				move = NO;
			}
			if (move) {
				recentlyTouchedItem = -1;
				int amount = 0;
				if (delta.x > 0) {
					amount = -maxShortcutsOnScreen;
				} else {
					amount = maxShortcutsOnScreen;
				}
				currentIndex += amount;
				if (currentIndex >= shortcuts.count) {
					//NSLog(@"%d >= %d", currentIndex, sc);
					currentIndex -= amount;
				} else if (currentIndex < 0) {
					currentIndex = 0;
				}
				CGRect frame = self.frame;
				CGRect superBounds = self.superview.bounds;
				frame.size.width = superBounds.size.width;
				frame.size = [self sizeThatFits:frame.size];
				[self setFrame:frame];
				[self setNeedsDisplay];
			}
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (touches.count == 1) {
		UITouch *touch = [touches anyObject];
		TouchInfo *ti = [touchInfoStore touchInfoForTouch:touch];
		if (!ti.moved) {
			CGPoint p = [touch locationInView:self];
			int i = floor(p.x/tileSize.width);
			i += currentIndex;
			if (i >= 0 && i < shortcuts.count) {
				Shortcut *sh = [shortcuts objectAtIndex:i];
				[sh invoke];
			}
		}
	}
	recentlyTouchedItem = -1;
	[self setNeedsDisplay];
	[touchInfoStore removeTouches:touches];
}

- (void)dealloc {
	[touchInfoStore release];
	[shortcuts release];
    [super dealloc];
}


@end

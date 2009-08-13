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
#import <QuartzCore/QuartzCore.h>

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
		Shortcut *shortcut = [[Shortcut alloc] initWithTitle:defaultShortcuts[i].title keys:keys selector:sel_registerName(defaultShortcuts[i].action) target:target arg:nil];
		[shortcuts addObject:shortcut];
		[shortcut release];
	}
	return shortcuts;
}

@interface ShortcutView ()
@property (assign) NSInteger highlightedIndex;
- (void)updateLayers;
@end

static const CGSize ShortcutTileSize  = { 40, 40 };
static const CGFloat InterCellPadding = 1;

#define TextColor        UIColor.whiteColor.CGColor
#define BackgroundColor  UIColor.grayColor.CGColor
#define HighlightColor   UIColor.greenColor.CGColor

@interface ShortcutLayer : CALayer
{
	NSString *title;
	BOOL isHighlighted;
}
@property (retain) NSString *title;
@property (assign) BOOL isHighlighted;
@end

@implementation ShortcutLayer
@synthesize title, isHighlighted;

- (id)init
{
	if (self = [super init]) {
		self.opacity       = 0.5;
		self.isHighlighted = NO;
		self.borderColor   = UIColor.whiteColor.CGColor;
		self.borderWidth   = 0.5;
		self.cornerRadius  = 5;
		self.bounds        = (CGRect){CGPointZero, ShortcutTileSize};
		self.anchorPoint   = CGPointZero;
	}
	return self;
}

- (void)setIsHighlighted:(BOOL)flag
{
	isHighlighted = flag;
	self.backgroundColor = self.isHighlighted ? HighlightColor : BackgroundColor;
}

- (void)drawInContext:(CGContextRef)context
{
	if (self.title) {
		UIFont* const font = [UIFont boldSystemFontOfSize:12];
		UIGraphicsPushContext(context);
		CGContextSetFillColorWithColor(context, TextColor);
		CGSize stringSize = [self.title sizeWithFont:font];
		CGPoint p;
		p.x = (self.bounds.size.width - stringSize.width) / 2;
		p.y = (self.bounds.size.height - stringSize.height) / 2;
		[self.title drawAtPoint:p withFont:font];
		UIGraphicsPopContext();
	}
}
@end

@implementation ShortcutView
// ==================
// = Setup/Teardown =
// ==================

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		shortcutLayers      = [NSMutableArray new];
		self.shortcuts      = DefaultShortcuts(self); // TODO make this nil-targeted
		self.pagingEnabled  = YES;
		self.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    }
    return self;
}

- (void)dealloc {
	self.shortcuts = nil;
	[self updateLayers];
	[super dealloc];
}

// ==============
// = Properties =
// ==============

@synthesize shortcuts, highlightedIndex;

- (void)setHighlightedIndex:(NSInteger)index {
	if (index != highlightedIndex) {
		highlightedIndex = index;
		[self updateLayers];
	}
}

- (void)updateLayers {
	// TODO re-use layers
	for(CALayer *layer in shortcutLayers) {
		[layer removeFromSuperlayer];
	}
	[shortcutLayers removeAllObjects];
	for(NSUInteger index = 0; index < self.shortcuts.count; ++index) {
		ShortcutLayer *layer = [ShortcutLayer layer];
		layer.position       = CGPointMake(layer.bounds.size.width * index, 0);
		layer.title          = [[self.shortcuts objectAtIndex:index] title];
		layer.isHighlighted  = index == self.highlightedIndex;
		[self.layer addSublayer:layer];
		[layer setNeedsDisplay];
		[shortcutLayers addObject:layer];
	}
}

- (void)setShortcuts:(NSArray*)newShortcuts {
	if (newShortcuts != shortcuts) {
		[shortcuts release];
		shortcuts = [newShortcuts retain];
		self.highlightedIndex = -1;
		[self updateLayers];
	}
}

// ===========
// = Drawing =
// ===========

- (void)layoutSubviews {
	CGFloat tilesOnScreen = self.bounds.size.width / ShortcutTileSize.width;
	CGFloat pages = ceil(self.shortcuts.count / tilesOnScreen);
	self.contentSize = CGSizeMake((pages * tilesOnScreen) * ShortcutTileSize.width, ShortcutTileSize.height);
}

- (CGSize)sizeThatFits:(CGSize)size {
	NSUInteger tilesOnScreen = size.width / ShortcutTileSize.width;
	return CGSizeMake(tilesOnScreen * ShortcutTileSize.width, ShortcutTileSize.height);
}

// ===========
// = Actions =
// ===========

- (void) showMainMenu:(id)obj {
	[[MainViewController instance] showMainMenu:obj]; // FIXME
}

- (void) showKeyboard:(id)obj {
	[[MainViewController instance] nethackKeyboard:obj]; // FIXME
}

// ==================
// = Touch Handling =
// ==================

- (NSUInteger)shortcutIndexForTouch:(UITouch *)touch {
	// FIXME I don’t think this logic is correct (but it works…)
	CGPoint point = [touch locationInView:touch.view];
	point = [touch.view convertPoint:point toView:self.superview];
	return [shortcutLayers indexOfObject:[self.layer hitTest:point]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSUInteger touchedIndex = [self shortcutIndexForTouch:touches.anyObject];
	if (touchedIndex != NSNotFound) {
		self.highlightedIndex = touchedIndex;
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	self.highlightedIndex = -1;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	NSUInteger touchedIndex = [self shortcutIndexForTouch:touches.anyObject];
	if (touchedIndex != NSNotFound) {
		[[shortcuts objectAtIndex:touchedIndex] invoke];
	}

	self.highlightedIndex = -1;
}
@end

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
#import <QuartzCore/QuartzCore.h>

NSString *const ShortcutPrefencesIdentifier = @"Shortcut Bar";

#define ShortcutMainMenuIdentifier @"mainMenu"
#define ShortcutKeyboardIdentifier @"keyboard"

static Shortcut *ShortcutForIdentifier (NSString *identifier) {
	NSString *title = identifier;
	SEL selector    = NULL;
	if ([identifier isEqualToString:ShortcutMainMenuIdentifier]) {
		title    = @"menu";
		selector = @selector(showMainMenu:);
	} else if ([identifier isEqualToString:ShortcutKeyboardIdentifier]) {
		title    = @"abc";
		selector = @selector(nethackKeyboard:);
	}
	return [[[Shortcut alloc] initWithTitle:title keys:(selector ? nil : identifier) selector:selector target:nil] autorelease];
}

static const CGSize ShortcutTileSize  = { 40, 40 };

#define TextColor        UIColor.whiteColor.CGColor
#define BackgroundColor  UIColor.blackColor.CGColor
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
		self.opacity       = 1.0f;
		self.isHighlighted = NO;
		self.borderColor   = UIColor.whiteColor.CGColor;
		self.borderWidth   = 0.5;
		self.cornerRadius  = 5;
		self.bounds        = (CGRect){CGPointZero, ShortcutTileSize};
		self.anchorPoint   = CGPointZero;
		[[self animationForKey:@"backgroundColor"] setDuration:0.1];
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

@interface ShortcutView ()
@property (assign) NSInteger highlightedIndex;
@property (nonatomic, retain) NSArray* shortcuts;
@property (nonatomic, retain) NSTimer* editTimer;
@end

@implementation ShortcutView
// ==================
// = Setup/Teardown =
// ==================

static NSArray *DefaultShortcuts () {
	return [NSArray arrayWithObjects:
		// Page 1
		@".",          @"20s",      @":",        @"99.",
		@";",          @"#",
		ShortcutMainMenuIdentifier,   ShortcutKeyboardIdentifier,
		// Page 2
		@"i",          @"e",        @"t",        @"f",
		@"z",          @"Z",        @"a",        @"o",
		// Page 3
		@"o",          @"^a",       @"r",        @"q",
		@"E",          @"Q",        @"d",        @"D",
		// Page 4
		@"w",          @"W",        @"P",        @"T",
		@"A",          @"R",        @"p",        @"^x",
	nil];
}

+ (void)load {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:DefaultShortcuts() forKey:ShortcutPrefencesIdentifier]];
	[pool drain];
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		shortcutLayers      = [NSMutableArray new];
		self.pagingEnabled  = YES;
		self.indicatorStyle = UIScrollViewIndicatorStyleWhite;
		[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:ShortcutPrefencesIdentifier options:NSKeyValueObservingOptionInitial context:NULL];
    }
    return self;
}

- (void)dealloc {
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:ShortcutPrefencesIdentifier];
	self.editTimer = nil;
	self.shortcuts = nil;
	[super dealloc];
}

// ==============
// = Properties =
// ==============

@synthesize shortcuts, highlightedIndex, editTimer;

- (void)setEditTimer:(NSTimer *)timer {
	if (timer != editTimer) {
		[editTimer invalidate];
		[editTimer release];
		editTimer = [timer retain];
	}
}

- (void)setHighlightedIndex:(NSInteger)index {
	if (index != highlightedIndex) {
		if (highlightedIndex >= 0 && highlightedIndex < shortcutLayers.count) {
			[[shortcutLayers objectAtIndex:highlightedIndex] setIsHighlighted:NO];
		}
		highlightedIndex = index;
		if (highlightedIndex >= 0 && highlightedIndex < shortcutLayers.count) {
			[[shortcutLayers objectAtIndex:highlightedIndex] setIsHighlighted:YES];
		}
	}
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	NSAssert([keyPath isEqualToString:ShortcutPrefencesIdentifier] && object == [NSUserDefaults standardUserDefaults], @"Unknown observed object/keypath");
	NSArray* identifiers = [[NSUserDefaults standardUserDefaults] arrayForKey:ShortcutPrefencesIdentifier];
	NSMutableArray *newShortcuts = [NSMutableArray arrayWithCapacity:identifiers.count];
	for (NSString *identifier in identifiers) {
		[newShortcuts addObject:ShortcutForIdentifier(identifier)];
	}
	self.shortcuts = newShortcuts;
	[[NSUserDefaults standardUserDefaults] synchronize];
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

// ==================
// = Touch Handling =
// ==================

- (void)startEdit:(NSTimer *)timer {
	self.highlightedIndex = -1;
}

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
		self.editTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(startEdit:) userInfo:[NSNumber numberWithInt:self.highlightedIndex] repeats:NO];
	} else {
		self.highlightedIndex = -1;
		self.editTimer = nil;
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	self.editTimer = nil;
	self.highlightedIndex = -1;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	self.editTimer = nil;
	NSUInteger touchedIndex = [self shortcutIndexForTouch:touches.anyObject];
	if (touchedIndex != NSNotFound) {
		[[shortcuts objectAtIndex:touchedIndex] invoke:self];

		self.highlightedIndex = -1;

		CALayer* layer = [shortcutLayers objectAtIndex:touchedIndex];

		CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
		[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
		[animation setToValue:(id)HighlightColor];
		[animation setAutoreverses:YES];
		[animation setDuration:0.1];
		[layer addAnimation:animation forKey:@"backgroundColor"];
	}

	self.highlightedIndex = -1;
}
@end

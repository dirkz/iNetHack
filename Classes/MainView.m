//
//  MainView.m
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

#import "MainView.h"
#import "MainViewController.h"
#import "Window.h"
#import "TilePosition.h"
#import "TileSet.h"
#import "ShortcutView.h"
#import "Shortcut.h"
#import "AsciiTileSet.h"

#define kKeyTileset (@"tileset")

@implementation MainView

@synthesize start, tileSize, dummyTextField, tileSet;

+ (void) initialize {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	[[NSUserDefaults standardUserDefaults]
	 registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:40] forKey:kKeyTileSize]];
	[pool drain];
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}

- (void) awakeFromNib {
	statusFont = [UIFont systemFontOfSize:16];
	
	// tileSize
	maxTileSize = CGSizeMake(40,40);
	float ts = [[NSUserDefaults standardUserDefaults] floatForKey:kKeyTileSize];
	tileSize = CGSizeMake(ts,ts);
	minTileSize = CGSizeMake(8,8);
	offset = CGPointMake(0,0);
	
	// load tileset
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *tilesetName = [defaults objectForKey:kKeyTileset];
	if (!tilesetName) {
		tilesetName = @"chozo40b";
	}
	CGSize tilesetTileSize = CGSizeMake(40,40);
	if ([tilesetName isEqualToString:@"ascii"]) {
		tileSet = [[AsciiTileSet alloc] initWithTileSize:tilesetTileSize];
	} else {
		if ([tilesetName isEqualToString:@"nhtiles"]) {
			tilesetTileSize = CGSizeMake(16,16);
			maxTileSize = tilesetTileSize;
			if (tileSize.width > 16) {
				tileSize = CGSizeMake(16,16);
			}
		} else if ([tilesetName isEqualToString:@"tiles32"]) {
			tilesetTileSize = CGSizeMake(32,32);
			maxTileSize = tilesetTileSize;
			if (tileSize.width > 32) {
				tileSize = CGSizeMake(32,32);
			}
		}
		NSString *imgName = [NSString stringWithFormat:@"%@.bmp", tilesetName];
		tileSet = [[TileSet alloc] initWithImage:[UIImage imageNamed:imgName] tileSize:tilesetTileSize];
	}
	petMark = [[UIImage imageNamed:@"petmark.png"] retain];

	shortcutView = [[ShortcutView alloc] initWithFrame:CGRectZero];
	[self addSubview:shortcutView];
	
	messageLabels = [[NSMutableArray alloc] init];

	dirty = YES;
}

- (BOOL)canBecomeFirstResponder { return YES; }

- (void)layoutSubviews {
	CGSize s = self.bounds.size;
	CGRect frame;
	
	s = [shortcutView sizeThatFits:s];
	frame.origin.x = (self.bounds.size.width-s.width)/2;
	frame.origin.y = self.bounds.size.height-s.height;
	frame.size.width = s.width;
	frame.size.height = s.height;
	shortcutView.frame = frame;
	
	// subviews like direction input
	for (UIView *v in self.subviews) {
		if (v != shortcutView && ![messageLabels containsObject:v]) {
			v.frame = self.frame;
		}
	}

	[shortcutView setNeedsDisplay];
}

#pragma mark drawing

- (void) drawTiledMap:(Window *)map clipRect:(CGRect)clipRect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGPoint center = CGPointMake(self.bounds.size.width/2-tileSize.width/2, self.bounds.size.height/2-tileSize.height/2);
	
	start = CGPointMake(-mainViewController.clip.x*tileSize.width + center.x + offset.x,
						-mainViewController.clip.y*tileSize.height + center.y + offset.y);

	// draw border
	CGRect borderRect = CGRectMake(start.x, start.y, map.width*tileSize.width, map.height*tileSize.height);
	float w = 2.0f;
	borderRect.origin.x -= w;
	borderRect.origin.y -= w;
	borderRect.size.width += 2*w;
	borderRect.size.height += 2*w;
	float borderColor[] = {1,1,1,1};
	CGContextSetStrokeColor(ctx, borderColor);
	CGContextStrokeRect(ctx, borderRect);

	for (int j = 0; j < map.height; ++j) {
		for (int i = 0; i < map.width; ++i) {
			int glyph = [map glyphAtX:i y:j];
			if (glyph != kNoGlyph) {
				/*
				 // might be handy for debugging ...
				int ochar, ocolor;
				unsigned special;
				mapglyph(glyph, &ochar, &ocolor, &special, i, j);
				 */
				CGRect r = CGRectMake(start.x+i*tileSize.width, start.y+j*tileSize.height, tileSize.width, tileSize.height);
				if (CGRectIntersectsRect(clipRect, r)) {
					UIImage *img = [UIImage imageWithCGImage:[tileSet imageForGlyph:glyph atX:i y:j]];
					[img drawInRect:r];
					if (u.ux == i && u.uy == j) {
						// hp100 calculation from qt_win.cpp
						int hp100;
						if (u.mtimedone) {
							hp100 = u.mhmax ? u.mh*100/u.mhmax : 100;
						} else {
							hp100 = u.uhpmax ? u.uhp*100/u.uhpmax : 100;
						}
						const static float colorValue = 0.7f;
						float playerRectColor[] = {colorValue, 0, 0, 0.5f};
						if (hp100 > 75) {
							playerRectColor[0] = 0;
							playerRectColor[1] = colorValue;
						} else if (hp100 > 50) {
							playerRectColor[2] = 0;
							playerRectColor[0] = playerRectColor[1] = colorValue;
						}
						CGContextSetStrokeColor(ctx, playerRectColor);
						CGContextStrokeRect(ctx, r);
					} else if (glyph_is_pet(glyph)) {
						[petMark drawInRect:r];
					}
				}
			}
		}
	}
}

- (CGSize) drawStrings:(NSArray *)strings withSize:(CGSize)size atPoint:(CGPoint)p {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	float white[] = {1,1,1,1};
	float transparentBackground[] = {0,0,0,0.6f};
	
	CGSize total = CGSizeMake(size.width, 0);
	CGRect backgroundRect = CGRectMake(p.x, p.y, size.width, size.height);
	for (NSString *s in strings) {
		UIFont *font = [self fontAndSize:&backgroundRect.size forString:s withFont:statusFont];
		CGContextSetFillColor(ctx, transparentBackground);
		CGRect backgroundRect = CGRectMake(p.x, p.y, backgroundRect.size.width, backgroundRect.size.height);
		CGContextFillRect(ctx, backgroundRect);
		CGContextSetFillColor(ctx, white);
		CGSize tmp = [s drawAtPoint:p withFont:font];
		p.y += tmp.height;
		total.height += tmp.height;
	}
	return total;
}

- (void)drawRect:(CGRect)rect {
	mainViewController = [MainViewController instance];
	Window *map = mainViewController.mapWindow;
	Window *status = mainViewController.statusWindow;
	Window *message = mainViewController.messageWindow;
	
	if (map) {
		[self drawTiledMap:map clipRect:rect];
	}
	
	for (UILabel *l in messageLabels) {
		[l removeFromSuperview];
	}
	[messageLabels removeAllObjects];
	
	CGSize statusSize;
	CGPoint p = CGPointMake(0,0);
	if (status) {
		if (status.strings.count > 0) {
			statusSize = [self drawStrings:[status.strings copy] withSize:CGSizeMake(self.bounds.size.width, 18)
								   atPoint:p];
		}
	}
	if (message) {
		p.y = statusSize.height;
		if (status.strings.count > 0) {
			statusSize = [self drawStrings:[message.strings copy] withSize:CGSizeMake(self.bounds.size.width, 18)
								   atPoint:p];
		}
	}
}

- (TilePosition *) tilePositionFromPoint:(CGPoint)p {
	p.x -= start.x;
	p.y -= start.y;
	TilePosition *tp = [TilePosition tilePositionWithX:p.x/tileSize.width y:p.y/tileSize.height];
	return tp;
}

- (UIFont *) fontAndSize:(CGSize *)size forStrings:(NSArray *)strings withFont:(UIFont *)font {
	CGSize dummySize;
	if (!size) {
		size = &dummySize;
	}
	*size = CGSizeMake(0,0);
	CGFloat maxWidth = self.bounds.size.width;
	for (NSString *s in strings) {
		CGSize tmpSize = [s sizeWithFont:font];
		while (tmpSize.width > maxWidth) {
			font = [font fontWithSize:font.pointSize-1];
			tmpSize = [s sizeWithFont:font];
		}
		size->width = tmpSize.width > size->width ? tmpSize.width:size->width;
		size->height += tmpSize.height;
	}
	return font;
}

- (UIFont *) fontAndSize:(CGSize *)size forString:(NSString *)s withFont:(UIFont *)font {
	CGSize dummySize;
	if (!size) {
		size = &dummySize;
	}
	*size = CGSizeMake(0,0);
	CGFloat maxWidth = self.bounds.size.width;
	CGSize tmpSize = [s sizeWithFont:font];
	while (tmpSize.width > maxWidth) {
		font = [font fontWithSize:font.pointSize-1];
		tmpSize = [s sizeWithFont:font];
	}
	size->width = tmpSize.width > size->width ? tmpSize.width:size->width;
	size->height += tmpSize.height;
	return font;
}

- (void) drawStrings:(NSArray *)strings atPosition:(CGPoint)p {
	UIFont *f = statusFont;
	CGFloat width = self.bounds.size.width;
	CGFloat height = 0;
	for (NSString *s in strings) {
		CGSize size = [s sizeWithFont:f];
		while (size.width > width) {
			CGFloat pointSize = f.pointSize-1;
			statusFont = [UIFont systemFontOfSize:pointSize];
			size = [s sizeWithFont:f];
		}
		height = size.height > height ? size.height:height;
	}
}

- (void) moveAlongVector:(CGPoint)d {
	dirty = YES;
	offset.x += d.x;
	offset.y += d.y;
}

- (void) resetOffset {
	dirty = YES;
	offset = CGPointMake(0,0);
}

- (void) zoom:(CGFloat)d {
	dirty = YES;
	d /= 5;
	CGSize originalSize = tileSize;
	tileSize.width += d;
	tileSize.width = round(tileSize.width);
	tileSize.height = tileSize.width;
	if (tileSize.width > maxTileSize.width) {
		tileSize = maxTileSize;
	} else if (tileSize.width < minTileSize.width) {
		tileSize = minTileSize;
	}
	CGFloat aspect = tileSize.width / originalSize.width;
	offset.x *= aspect;
	offset.y *= aspect;
	[self setNeedsDisplay];
}

- (BOOL) isMoved {
	if (offset.x != 0 || offset.y != 0) {
		return YES;
	}
	return NO;
}

- (void)dealloc {
	[tileSet release];
	[shortcutView release];
	[petMark release];
	[messageLabels release];
    [super dealloc];
}


@end

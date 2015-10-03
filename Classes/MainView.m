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
@synthesize status, map, message;
@synthesize cache;

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
	[super awakeFromNib];
	
	bundleVersionString = [[NSString alloc] initWithFormat:@"%@",
						   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
	statusFont = [UIFont systemFontOfSize:16];
	
	// tileSize
	maxTileSize = tilesetTileSize = CGSizeMake(32,32);
    maxTileSize = CGSizeMake(48,48);    //iNethack2 increasing max zoom-in a little bit.
	minTileSize = CGSizeMake(8,8);
	offset = CGPointMake(0,0);
	float ts = [[NSUserDefaults standardUserDefaults] floatForKey:kKeyTileSize];
	tileSize = CGSizeMake(ts,ts);
	if (tileSize.width > maxTileSize.width) {
		tileSize = maxTileSize;
	} else if (tileSize.width < minTileSize.width) {
		tileSize = minTileSize;
	}
    
    cache = [NSCache new]; //iNethack2: glyph cache
    
	// load tileset
	NSString *tilesetName = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyTileset];
	if (!tilesetName) {
		tilesetName = @"chozo32b";
	}
	if ([tilesetName isEqualToString:@"ascii"] || [tilesetName isEqualToString:@"asciimono"]) {
		asciiTileset = YES;
		tileSet = [[AsciiTileSet alloc] initWithTileSize:tilesetTileSize];
	} else {
		if ([tilesetName isEqualToString:@"nhtiles"]) {
			tilesetTileSize = CGSizeMake(16,16);
			maxTileSize = CGSizeMake(32,32);
			if (tileSize.width > 32) {
				tileSize = CGSizeMake(32,32);
			}
		} else if ([tilesetName isEqualToString:@"tiles32"]) {
			tilesetTileSize = CGSizeMake(32,32);
			maxTileSize = tilesetTileSize;
			if (tileSize.width > 32) {
				tileSize = CGSizeMake(32,32);
			}
        } else if ([tilesetName isEqualToString:@"nextstep"]) {
            tilesetTileSize = CGSizeMake(10,10);
            maxTileSize = CGSizeMake(30,30);
            if (tileSize.width > 30) {
                tileSize = CGSizeMake(30,30);
            }
        }
        NSString *imgName = [NSString stringWithFormat:@"%@.png", tilesetName];
		UIImage *tilesetImage = [UIImage imageNamed:imgName];
		if (!tilesetImage) {
			tilesetImage = [UIImage imageNamed:@"chozo32b.png"];
			tilesetTileSize = CGSizeMake(32,32);
			maxTileSize = tilesetTileSize;
			[[NSUserDefaults standardUserDefaults] setObject:@"chozo32b" forKey:kKeyTileset];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
		tileSet = [[TileSet alloc] initWithImage:tilesetImage tileSize:tilesetTileSize];
	}
	tileSets[0] = tileSet;
	tileSets[1] = nil;
	NSString *bundlePath = [[NSBundle mainBundle] resourcePath];
	petMark = [[UIImage alloc] initWithContentsOfFile:[bundlePath stringByAppendingPathComponent:@"petmark.png"]];

	shortcutView = [[ShortcutView alloc] initWithFrame:CGRectZero];
	[self addSubview:shortcutView];

	// reuse the more button
	moreButton = [[UIButton buttonWithType:UIButtonTypeDetailDisclosure] retain];
}

- (CGPoint) subViewedCenter {
    return CGPointMake([MainView screenSize].width/2, ([MainView screenSize].height-shortcutView.bounds.size.height)/2);
}

- (BOOL)canBecomeFirstResponder { return YES; }

- (void)layoutSubviews {
    CGSize s = [MainView screenSize];

    CGRect frame;

    s = [shortcutView sizeThatFits:s];

    frame.origin.x = ([MainView screenSize].width-s.width)/2;
    frame.origin.y = [MainView screenSize].height-s.height;
    
    frame.size.width = s.width;
	frame.size.height = s.height;
    shortcutView.frame = frame;
	
	// subviews like direction input
	for (UIView *v in self.subviews) {
		if (v != shortcutView && v != moreButton) {
			v.frame = self.frame;
		}
	}

	[shortcutView setNeedsDisplay];
}

//iNethack2: screenSize that works with both iOS7 + 8
+ (CGSize)screenSize {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        return CGSizeMake(screenSize.height, screenSize.width);
    }
    return screenSize;
}

#pragma mark drawing

- (void) drawTiledMap:(Window *)m clipRect:(CGRect)clipRect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGPoint center = self.subViewedCenter;
	center.x -= tileSize.width/2;
	center.y -= tileSize.height/2;
	
	start = CGPointMake(-mainViewController.clip.x*tileSize.width + center.x + offset.x,
						-mainViewController.clip.y*tileSize.height + center.y + offset.y);

	// indicate level boundaries
	float bgColor[] = {0.1f,0.1f,0.f,1.0f};
	float levelBgColor[] = {0.0f,0.0f,0.0f,1.0f};
    CGColorRef   bgColorRef = [[UIColor colorWithRed:bgColor[0] green:bgColor[1] blue:bgColor[2] alpha:bgColor[3]] CGColor];
    CGColorRef   levelBgColorRef = [[UIColor colorWithRed:levelBgColor[0] green:levelBgColor[1] blue:levelBgColor[2] alpha:levelBgColor[3]] CGColor];
    //CGContextSetStrokeColor(ctx, playerRectColor);
    CGContextSetFillColorWithColor(ctx, bgColorRef);
    
	CGContextFillRect(ctx, clipRect);
	CGRect borderRect = CGRectMake(start.x, start.y, m.width*tileSize.width, m.height*tileSize.height);
    CGContextSetFillColorWithColor(ctx, levelBgColorRef);

	CGContextFillRect(ctx, borderRect);
	
	// draw version info
	CGPoint versionLocation = borderRect.origin;

    NSAttributedString *attributedText =
    [[NSAttributedString alloc]
     initWithString:bundleVersionString
     attributes:@
     {
     NSFontAttributeName: statusFont,

     }];
    CGFloat width = 16;
    CGRect rect = [attributedText boundingRectWithSize:(CGSize){width, CGFLOAT_MAX}
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    CGSize size = rect.size;

    versionLocation.x += borderRect.size.width - size.width;
	versionLocation.y += borderRect.size.height;
	float versionStringColor[] = {0.8f,0.8f,0.8f,1.0f};
    UIColor *versionStringColorCol = [UIColor colorWithRed:versionStringColor[0] green:versionStringColor[1] blue:versionStringColor[2] alpha:versionStringColor[3]];

    [bundleVersionString drawAtPoint:versionLocation withAttributes:@ { NSFontAttributeName: statusFont, NSForegroundColorAttributeName: versionStringColorCol}];

    for (int j = 0; j < m.height; ++j) {
		for (int i = 0; i < m.width; ++i) {
			int glyph = [m glyphAtX:i y:j];
			if (glyph != kNoGlyph) {
				/*
				 // might be handy for debugging ...
				int ochar, ocolor;
				unsigned special;
				mapglyph(glyph, &ochar, &ocolor, &special, i, j);
				 */
				CGRect r = CGRectMake(start.x+i*tileSize.width, start.y+j*tileSize.height, tileSize.width, tileSize.height);
				if (CGRectIntersectsRect(clipRect, r)) {
					//UIImage *img = [UIImage imageWithCGImage:[tileSet imageForGlyph:glyph atX:i y:j]];
                    //UIImage * img = [self imageForGlyph:glyph size:r.size.width];
                    UIImage * img = [self imageForGlyph:glyph size:tilesetTileSize.width]; //use native width of tile rather than cache for each scaled size.

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
                        //iNethack2 fix for stroke color.
                        CGColorRef   playerRectColorRef = [[UIColor colorWithRed:playerRectColor[0] green:playerRectColor[1] blue:playerRectColor[2] alpha:playerRectColor[3]] CGColor];
                        CGContextSetStrokeColorWithColor(ctx, playerRectColorRef);
						CGContextStrokeRect(ctx, r);
					} else if (glyph_is_pet(glyph)) {
						[petMark drawInRect:r];
					}
				}
			}
		}
	}

    [self.layer needsDisplay];
}

- (void) resetGlyphCache {
    if ( cache != nil ) {
        [cache removeAllObjects];
    }
}

- (UIImage *)imageForGlyph:(int)glyph size:(int)size
{
    NSNumber * key = @(size*MAX_GLYPH + glyph);

    UIImage * img = [cache objectForKey:key];
    if ( img == nil ) {
        //#if 1
        CGImageRef imageRef = [tileSet imageForGlyph:glyph];
        //#else
        //        CGImageRef imageRef = [tileSet imageForGlyph:glyph atX:i y:j];
        //#endif
        CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                    size, size,
                                                    CGImageGetBitsPerComponent(imageRef),
                                                    0,
                                                    CGImageGetColorSpace(imageRef),
                                                    CGImageGetBitmapInfo(imageRef));

        CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
        CGContextDrawImage(bitmap, CGRectMake(0,0,size,size), imageRef);
        CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
        img = [UIImage imageWithCGImage:newImageRef];
        CGContextRelease(bitmap);
        CGImageRelease(newImageRef);
        
        [cache setObject:img forKey:key];
    }
    return img;
}


- (void) checkForRogueLevel {
	if (u.uz.dlevel && Is_rogue_level(&u.uz)) {
		if (!tileSets[1]) {
			tileSet = tileSets[1] = [[AsciiTileSet alloc] initWithTileSize:tilesetTileSize];
		} else {
			tileSet = tileSets[1];
		}
	} else {
		tileSet = tileSets[0];
		[tileSets[1] release];
		tileSets[1] = nil;
	}
}

- (CGSize) drawStrings:(NSArray *)strings withSize:(CGSize)size atPoint:(CGPoint)p {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	CGSize total = CGSizeMake(size.width, 0);
	CGRect backgroundRect = CGRectMake(p.x, p.y, size.width, size.height);
    NSShadow *shadow = [NSShadow new];
    [shadow setShadowColor: [UIColor colorWithWhite:0.0f alpha:1.0f]];
    [shadow setShadowOffset: CGSizeMake(1.0f, 1.0f)];
    [shadow setShadowBlurRadius:1.5f];

	for (NSString *s in strings) {
        
		UIFont *font = [self fontAndSize:&backgroundRect.size forString:s withFont:statusFont];

        CGRect backgroundRect = CGRectMake(p.x, p.y, backgroundRect.size.width, backgroundRect.size.height);
		CGContextFillRect(ctx, backgroundRect);
        CGSize tmp = [s sizeWithAttributes:@{NSFontAttributeName:font}];
        //iNethack2: some users reported missing status bars. Couldn't reproduce, but using below as it worked for the messages...
        [s drawAtPoint:p withAttributes:@{ NSFontAttributeName:font, NSForegroundColorAttributeName: [UIColor whiteColor], NSShadowAttributeName: shadow}];
        //iNethack2: old drawAtPoint below
        //   [s drawAtPoint:p withAttributes: @ {NSFontAttributeName:font, NSForegroundColorAttributeName: [UIColor whiteColor],NSShadowAttributeName: shadow,
        // NSBackgroundColorAttributeName: [UIColor clearColor]}]; //iNethack2: fix for drawAtPoint
        
        
		p.y += tmp.height;
		total.height += tmp.height;
	}
	return total;
}

- (void)drawRect:(CGRect)rect {
	mainViewController = [MainViewController instance];
	
	// retain needed windows to avoid crash on exit
	self.map = mainViewController.mapWindow;
	self.status = mainViewController.statusWindow;
	self.message = mainViewController.messageWindow;
	
	CGPoint center = self.subViewedCenter;
    NSShadow *shadow = [NSShadow new];
    [shadow setShadowColor: [UIColor colorWithWhite:0.0f alpha:1.0f]];
    [shadow setShadowOffset: CGSizeMake(1.0f, 1.0f)];
    [shadow setShadowBlurRadius:1.5f];
    
	if (map) {
		[self checkForRogueLevel];
		[self drawTiledMap:map clipRect:rect];
		if (map.blocking) {
			CGContextRef ctx = UIGraphicsGetCurrentContext();
            CGColorRef   whiteColorRef = [[UIColor colorWithRed:1 green:1 blue:1 alpha:1] CGColor];
            CGContextSetFillColorWithColor(ctx, whiteColorRef);
			NSString *m = @"Single tap to continue ...";
            CGSize size = [m sizeWithAttributes:@{NSFontAttributeName:statusFont}];
			center.x -= size.width/2;
			center.y -= size.height/2;
            [m drawAtPoint:center withAttributes:@{NSFontAttributeName:statusFont, NSForegroundColorAttributeName: [UIColor whiteColor], NSShadowAttributeName: shadow}];
        }
	}
	
	CGSize statusSize = CGSizeMake(0,0);
	CGPoint p = CGPointMake(0,0);
	if (status) {
		NSArray *strings = nil;
		[status lock];
		strings = [status.strings copy];
		[status unlock];
        //iNethack2: sometimes the below doesnt draw for some people?
		if (strings.count > 0) {
            statusSize = [self drawStrings:[strings copy] withSize:CGSizeMake([MainView screenSize].width, 18) atPoint:p];
		}
	}
	if (message) {
		[moreButton removeFromSuperview];
        CGSize avgLineSize = [@"O" sizeWithAttributes: @{ NSFontAttributeName: statusFont} ];
		float maxY = center.y - avgLineSize.height*2;
		p.y = statusSize.height;
		NSArray *strings = nil;
		[message lock];
		strings = [message.strings copy];
		[message unlock];

		if (strings.count > 0) {
            CGSize bounds = [MainView screenSize];
			for (NSString *s in strings) {
                CGSize size = [s sizeWithAttributes: @ { NSFontAttributeName: statusFont}];
				if (p.y > maxY) {
					p.x = 0;
					p.y += size.height + 2;
					CGRect frame = moreButton.frame;
					frame.origin = p;
					moreButton.frame = frame;
					[moreButton addTarget:[MainViewController instance] action:@selector(nethackShowLog:)
						 forControlEvents:UIControlEventTouchUpInside];
					[self addSubview:moreButton];
					break;
				}
				if (p.x + size.width < bounds.width) {
                    size = [s sizeWithAttributes: @ { NSFontAttributeName: statusFont}];
                    [s drawAtPoint:p withAttributes:@{ NSFontAttributeName:statusFont, NSForegroundColorAttributeName: [UIColor whiteColor], NSShadowAttributeName: shadow}];
					p.x += size.width + 4;
				} else {
					if (p.x != 0) {
						p.y += size.height + 2;
					}
					p.x = 0;
					UIFont *font = [self fontAndSize:&size forString:s withFont:statusFont];
                    size = [s sizeWithAttributes: @ { NSFontAttributeName: font}];
                    [s drawAtPoint:p withAttributes:@{ NSFontAttributeName:font, NSForegroundColorAttributeName: [UIColor whiteColor], NSShadowAttributeName: shadow}];
					p.x += size.width;
				}
			}
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
    CGFloat maxWidth = [MainView screenSize].width;
	for (NSString *s in strings) {
        CGSize tmpSize = [s sizeWithAttributes:@ { NSFontAttributeName:font}];
		while (tmpSize.width > maxWidth) {
			font = [font fontWithSize:font.pointSize-1];
            tmpSize = [s sizeWithAttributes:@ { NSFontAttributeName:font}];
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
    CGFloat maxWidth = [MainView screenSize].width;
    CGSize tmpSize = [s sizeWithAttributes:@ { NSFontAttributeName:font}];
	while (tmpSize.width > maxWidth) {
		font = [font fontWithSize:font.pointSize-1];
        tmpSize = [s sizeWithAttributes:@ { NSFontAttributeName:font}];
	}
    size->width = tmpSize.width > size->width ? tmpSize.width:size->width;
	size->height += tmpSize.height;
	return font;
}

- (void) drawStrings:(NSArray *)strings atPosition:(CGPoint)p {
	UIFont *f = statusFont;
    CGFloat width = [MainView screenSize].width;
	CGFloat height = 0;
	for (NSString *s in strings) {
        CGSize size = [s sizeWithAttributes:@ { NSFontAttributeName:f}];
		while (size.width > width) {
			CGFloat pointSize = f.pointSize-1;
			statusFont = [UIFont systemFontOfSize:pointSize];
            size = [s sizeWithAttributes:@ { NSFontAttributeName:f}];
		}
		height = size.height > height ? size.height:height;
	}
}

- (void) moveAlongVector:(CGPoint)d {
	offset.x += d.x;
	offset.y += d.y;
}

- (void) resetOffset {
	offset = CGPointMake(0,0);
}

- (void) zoom:(CGFloat)d {
	d /= 5;
	CGSize originalSize = tileSize;
	tileSize.width += d;
	tileSize.width = round(tileSize.width);
	tileSize.height = tileSize.width;
	if (tileSize.width> maxTileSize.width) {
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
	[tileSets[0] release];
	[tileSets[1] release];
	[shortcutView release];
	[petMark release];
	[bundleVersionString release];
    [super dealloc];
}

@end

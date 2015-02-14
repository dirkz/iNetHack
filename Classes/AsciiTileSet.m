//
//  AsciiTileSet.m
//  iNetHack
//
//  Created by dirk on 8/24/09.
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

#import "AsciiTileSet.h"

#include "hack.h"
#include "display.h"

/*
static float _colorTable[][4] = {
{0,0,0,1}, // CLR_BLACK
{1,0,0,1}, // CLR_RED
{0,1,0,1}, // CLR_GREEN
{0.6f,0.3f,0.2f,1}, // CLR_BROWN
{0,0,1,1}, // CLR_BLUE
{1,0,1,1}, // CLR_MAGENTA
{0,0.3f,0.3f,1}, // CLR_CYAN
{0.7f,0.7f,0.7f,1}, // CLR_GRAY
{1,0,0,1}, // CLR_RED / NO_COLOR
{1,0.6f,0,1}, // CLR_ORANGE
{0.5f,1,0,1}, // CLR_BRIGHT_GREEN
{1,1,0,1}, // CLR_YELLOW
{0.4f,0.6f,0.9f,1}, // CLR_BRIGHT_BLUE
{0.2f,0,0.2f,1}, // CLR_BRIGHT_MAGENTA
{0,1,1,1}, // CLR_BRIGHT_CYAN
{1,1,1,1}, // CLR_WHITE
};
 */

@implementation AsciiTileSet

- (id) initWithTileSize:(CGSize)ts {
	if (self = [super initWithImage:nil tileSize:ts]) {
		numImages = MAX_GLYPH;
		size_t size = numImages * sizeof(CGImageRef);
		images = malloc(size);
		memset(images, 0, size);
		UIColor *brightGreenColor = [[UIColor alloc] initWithRed:0 green:1 blue:0 alpha:1];
		UIColor *brightBlueColor = [[UIColor alloc] initWithRed:0 green:0 blue:1 alpha:1];
		UIColor *brightMagentaColor = [[UIColor alloc] initWithRed:0.2f green:0 blue:0.2f alpha:1];
		UIColor *brightCyanColor = [[UIColor alloc] initWithRed:0 green:1 blue:1 alpha:1];
        UIColor *blackColor = [[UIColor alloc] initWithRed:0.2f green:0.2f blue:0.2f alpha:1];
		colorTable = [[NSArray alloc] initWithObjects:
					  blackColor, //[UIColor blackColor], //iNethack2: use dark grey so you can see black monsters/items
					  [UIColor redColor],
					  [UIColor greenColor],
					  [UIColor brownColor],
					  [UIColor blueColor],
					  [UIColor magentaColor],
					  [UIColor cyanColor],
					  [UIColor grayColor],
					  [UIColor redColor], // NO_COLOR
					  [UIColor orangeColor],
					  brightGreenColor,
					  [UIColor yellowColor],
					  brightBlueColor,
					  brightMagentaColor,
					  brightCyanColor,
					  [UIColor whiteColor],
					  nil];
		[brightGreenColor release];
		[brightBlueColor release];
		[brightMagentaColor release];
		[brightCyanColor release];
	}
	return self;
}

- (id) initWithImage:(UIImage *)image tileSize:(CGSize)ts {
	return [self initWithTileSize:ts];
}

- (CGImageRef) imageForGlyph:(int)g atX:(int)x y:(int)y {
	iflags.use_color = TRUE;
	int tile = [TileSet glyphToTileIndex:g];
	if (!images[tile]) {
		UIFont *font = [UIFont systemFontOfSize:28];
		int ochar, ocolor;
		unsigned special;
		mapglyph(g, &ochar, &ocolor, &special, x, y);
		//NSLog(@"glyph %d, tile %d %c", g, tile, ochar);
		NSString *s = [NSString stringWithFormat:@"%c", ochar];
        CGSize size = [s sizeWithAttributes:@{NSFontAttributeName:font}];
		CGPoint p = CGPointMake((tileSize.width-size.width)/2, (tileSize.height-size.height)/2);
		UIGraphicsBeginImageContext(tileSize);
		CGContextRef ctx = UIGraphicsGetCurrentContext();
		UIColor *color = [self mapNetHackColor:ocolor];
		CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
		CGRect r = CGRectZero;
		r.size = tileSize;
		CGContextFillRect(ctx, r);
		CGContextSetFillColorWithColor(ctx, color.CGColor);
        [s drawAtPoint:p withAttributes:@ { NSFontAttributeName: font, NSForegroundColorAttributeName: color }];
		UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
		images[tile] = CGImageRetain(img.CGImage);
		UIGraphicsEndImageContext();
	}
	return images[tile];
}

- (UIColor *) mapNetHackColor:(int)ocolor {
	return [colorTable objectAtIndex:ocolor];
}

- (void) dealloc {
	[colorTable release];
	[super dealloc];
}

@end

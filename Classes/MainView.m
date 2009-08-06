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
#import "TiledImages.h"
#import "ShortcutView.h"
#import "Shortcut.h"

extern short glyph2tile[];

@implementation MainView

@synthesize start, tileSize, dummyTextField;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}

- (void) awakeFromNib {
	statusFont = [UIFont systemFontOfSize:12];
	flashMessageFont = [UIFont systemFontOfSize:24];
	images = [[TiledImages alloc] initWithImage:[UIImage imageNamed:@"absurd64.bmp"] tileSize:CGSizeMake(64,64)];
	tileSize = maxTileSize = CGSizeMake(40,40);
	minTileSize = CGSizeMake(8,8);
	offset = CGPointMake(0,0);
	
	NSArray *shortcuts = [[NSArray alloc] initWithObjects:
						  [[Shortcut alloc] initWithTitle:@"." key:'.'],
						  [[Shortcut alloc] initWithTitle:@"20s" keys:@"20s"],
						  [[Shortcut alloc] initWithTitle:@"," key:','],
						  [[Shortcut alloc] initWithTitle:@"o" key:'o'],
						  [[Shortcut alloc] initWithTitle:@"^d" key:C('d')],
						  [[Shortcut alloc] initWithTitle:@"^a" key:C('a')],
						  nil];
	shortcutView = [[ShortcutView alloc] initWithShortcuts:shortcuts];
	[shortcutView releaseShortcuts];
	
	shortcuts = [[NSArray alloc] initWithObjects:
				 [[Shortcut alloc] initWithTitle:@"t" key:'t'],
				 [[Shortcut alloc] initWithTitle:@"f" key:'f'],
				 [[Shortcut alloc] initWithTitle:@"z" key:'z'],
				 [[Shortcut alloc] initWithTitle:@"#" key:'#'],
				 [[Shortcut alloc] initWithTitle:@"abc" keys:nil
										selector:@selector(showKeyboard:) target:self arg:nil],
				 [[Shortcut alloc] initWithTitle:@"menu" keys:nil
										selector:@selector(showMainMenu:) target:self arg:nil],
				 nil];
	shortcutViewBottom = [[ShortcutView alloc] initWithShortcuts:shortcuts];
	[shortcutViewBottom releaseShortcuts];
	
	[self addSubview:shortcutView];
	[self addSubview:shortcutViewBottom];
}

- (void)layoutSubviews {
	CGSize s = CGSizeMake(0,0);
	CGRect frame;
	
	s = [shortcutView sizeThatFits:s];
	frame.origin.x = (self.bounds.size.width-s.width)/2;
	frame.origin.y = 0;
	frame.size.width = s.width;
	frame.size.height = s.height;
	shortcutView.frame = frame;

	s = [shortcutViewBottom sizeThatFits:s];
	frame.origin.x = (self.bounds.size.width-s.width)/2;
	frame.origin.y = self.bounds.size.height-s.height;
	frame.size.width = s.width;
	frame.size.height = s.height;
	shortcutViewBottom.frame = frame;
	
	for (UIView *v in self.subviews) {
		if (v != shortcutView && v != shortcutViewBottom) {
			v.frame = self.frame;
		}
	}
}

#pragma mark ad-hoc methods for shortcuts

- (void) showMainMenu:(id)obj {
	[[MainViewController instance] showMainMenu:obj];
}

- (void) showKeyboard:(id)obj {
	[[MainViewController instance] nethackKeyboard:obj];
}

#pragma mark drawing

- (void) drawTiledMap:(Window *)map inContext:(CGContextRef)ctx {
	CGPoint center = CGPointMake(self.bounds.size.width/2-tileSize.width/2, self.bounds.size.height/2-tileSize.height/2);
	
	start = CGPointMake(-mainViewController.clipx*tileSize.width + center.x + offset.x,
						-mainViewController.clipy*tileSize.height + center.y + offset.y);

	for (int j = 0; j < map.height; ++j) {
		for (int i = 0; i < map.width; ++i) {
			int glyph = [map glyphAtX:i y:j];
			if (glyph) {
				int ochar, ocolor;
				unsigned special;
				mapglyph(glyph, &ochar, &ocolor, &special, i, j);
				CGRect r = CGRectMake(start.x+i*tileSize.width, start.y+j*tileSize.height, tileSize.width, tileSize.height);
				int t = glyph2tile[glyph];
				CGImageRef img = [images imageAt:t];
				//CGContextDrawImage(ctx, r, img);
				UIImage *i = [UIImage imageWithCGImage:img];
				[i drawInRect:r];
			}
			if (glyph_is_pet(glyph)) {
				// todo
			}
		}
	}
}

- (void)drawRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	mainViewController = [MainViewController instance];
	Window *map = mainViewController.mapWindow;
	Window *status = mainViewController.statusWindow;
	Window *message = mainViewController.messageWindow;
	if (map) {
		[self drawTiledMap:map inContext:ctx];
	}
	
	float white[] = {1,1,1,1};
	if (message) {
		if (message.strings.count > 0) {
			CGSize totalSize;
			NSArray *strings = [NSArray arrayWithArray:message.strings];
			UIFont *font = [self fontAndSize:&totalSize forStrings:strings withFont:statusFont];
			CGContextSetStrokeColor(ctx, white);
			CGContextSetFillColor(ctx, white);
			CGPoint p = CGPointMake(0, shortcutView.frame.size.height);
			for (NSString *s in strings) {
				CGSize tmp = [s drawAtPoint:p withFont:font];
				p.y += tmp.height;
			}
		}
	}
	if (status) {
		if (status.strings.count > 0) {
			CGSize totalSize;
			NSArray *strings = [NSArray arrayWithArray:status.strings];
			UIFont *font = [self fontAndSize:&totalSize forStrings:strings withFont:statusFont];
			CGContextSetStrokeColor(ctx, white);
			CGContextSetFillColor(ctx, white);
			CGPoint p = CGPointMake(0, self.bounds.size.height-totalSize.height-shortcutViewBottom.frame.size.height);
			for (NSString *s in strings) {
				CGSize tmp = [s drawAtPoint:p withFont:font];
				p.y += tmp.height;
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
	offset.x += d.x;
	offset.y += d.y;
}

- (void) resetOffset {
	offset = CGPointMake(0,0);
}

- (void) zoom:(CGFloat)d {
	d /= 20;
	CGSize originalSize = tileSize;
	tileSize.width += d;
	tileSize.height += d;
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

- (void)dealloc {
	[images release];
	[shortcutView release];
    [super dealloc];
}


@end

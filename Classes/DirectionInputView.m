//
//  DirectionInputView.m
//  iNetHack
//
//  Created by dirk on 7/4/09.
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

#import "DirectionInputView.h"
#import "Shortcut.h"

@implementation DirectionInputView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}

- (void) awakeFromNib {
	tileSize = CGSizeMake(48,48);
}

- (CGRect *) rects {
	return rects;
}

- (Shortcut **) shortcuts {
	return shortcuts;
}

- (void) createRects {
	CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
	float tilesAbove = 1.5f;
	float tilesLeft = (float) kNumCols/2;
	CGPoint start = CGPointMake(center.x-(tilesLeft*tileSize.width), center.y-(tilesAbove*tileSize.height));
	for (int j = 0; j < kNumRows; ++j) {
		for (int i = 0; i < kNumCols; ++i) {
			int n = j*kNumCols+i;
			rects[n] = CGRectMake(start.x+i*tileSize.width, start.y+j*tileSize.height, tileSize.width, tileSize.height);
		}
	}
	shortcuts[0] = [[Shortcut alloc] initWithTitle:@"y" keys:@"y"];
	shortcuts[1] = [[Shortcut alloc] initWithTitle:@"k" keys:@"k"];
	shortcuts[2] = [[Shortcut alloc] initWithTitle:@"u" keys:@"u"];
	shortcuts[3] = [[Shortcut alloc] initWithTitle:@"h" keys:@"h"];
	shortcuts[4] = [[Shortcut alloc] initWithTitle:@"." keys:@"."];
	shortcuts[5] = [[Shortcut alloc] initWithTitle:@"l" keys:@"l"];
	shortcuts[6] = [[Shortcut alloc] initWithTitle:@"b" keys:@"b"];
	shortcuts[7] = [[Shortcut alloc] initWithTitle:@"j" keys:@"j"];
	shortcuts[8] = [[Shortcut alloc] initWithTitle:@"n" keys:@"n"];
	shortcuts[9] = [[Shortcut alloc] initWithTitle:@"<" keys:@"<"];
	shortcuts[10] = [[Shortcut alloc] initWithTitle:@"ESC" keys:@"\x1b"];
	shortcuts[11] = [[Shortcut alloc] initWithTitle:@">" keys:@">"];;
}

- (void)drawRect:(CGRect)rect {
	UIFont *font = [UIFont systemFontOfSize:24];
	float white[] = {1,1,1,1};
	float *color = white;
	[self createRects];
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetFillColor(ctx, color);
	CGContextSetStrokeColor(ctx, color);
	for (int i = 0; i < kNumRects; ++i) {
		CGContextStrokeRect(ctx, rects[i]);
		Shortcut *sh = shortcuts[i];
		if (sh) {
			CGSize size = [sh.title sizeWithFont:font];
			CGPoint p = CGPointMake(rects[i].origin.x + (tileSize.width-size.width)/2,
									rects[i].origin.y + (tileSize.height-size.height)/2);
			[sh.title drawAtPoint:p withFont:font];
		}
	}
}


- (void)dealloc {
	for (int i = 0; i < kNumRects; ++i) {
		[shortcuts[i] release];
	}
    [super dealloc];
}


@end

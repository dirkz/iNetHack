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
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  iNetHack is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with iNetHack.  If not, see <http://www.gnu.org/licenses/>.

#import "DirectionInputView.h"


@implementation DirectionInputView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}

- (void) awakeFromNib {
	tileSize = CGSizeMake(64,64);
}

- (CGRect *) rects {
	return rects;
}

- (void) setRects:(CGRect *)r {
	for (int i = 0; i < kNumRects; ++i) {
		rects[i] = r[i];
	}
}

- (void) createRects {
	CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
	CGPoint start = CGPointMake(center.x-(1.5f*tileSize.width), center.y-(1.5f*tileSize.height));
	for (int j = 0; j < kNumRows; ++j) {
		for (int i = 0; i < kNumCols; ++i) {
			rects[j*kNumRows+i] = CGRectMake(start.x+i*tileSize.width, start.y+j*tileSize.height, tileSize.width, tileSize.height);
		}
	}
}

- (void)drawRect:(CGRect)rect {
	float white[] = {1,1,1,1};
	float *color = white;
	[self createRects];
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetFillColor(ctx, color);
	CGContextSetStrokeColor(ctx, color);
	for (int i = 0; i < kNumRects; ++i) {
		CGContextStrokeRect(ctx, rects[i]);
	}
}


- (void)dealloc {
    [super dealloc];
}


@end

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

@implementation ShortcutView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		self.clearsContextBeforeDrawing = YES;
		recentlyTouchedItem = -1;
		font = [UIFont systemFontOfSize:12];
		tileSize = CGSizeMake(40,40);
		self.alpha = 0.7f;
    }
    return self;
}

- (id) initWithShortcuts:(NSArray *)sh {
	if (self = [self initWithFrame:CGRectZero]) {
		shortcuts = [sh retain];
	}
	return self;
}

- (void) releaseShortcuts {
	for (Shortcut *sh in shortcuts) {
		[sh release];
	}
}

- (CGSize)sizeThatFits:(CGSize)size {
	CGSize s = CGSizeMake(tileSize.width * shortcuts.count, tileSize.height);
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
	int i = 0;
	for (Shortcut *sh in shortcuts) {
		float pad = 4.0f;
		float halfPad = pad/2;
		CGRect r = CGRectMake(current.x+halfPad, current.y+halfPad, tileSize.width-pad, tileSize.height-pad);
		if (i == recentlyTouchedItem) {
			CGContextSetFillColor(ctx, green);
		} else {
			CGContextSetFillColor(ctx, grey);
		}
		CGContextFillRect(ctx, r);
		CGContextSetFillColor(ctx, white);
		CGSize stringSize = [sh.title sizeWithFont:font];
		CGPoint p = current;
		p.x += (tileSize.width-stringSize.width) / 2;
		p.y += (tileSize.height-stringSize.height) / 2;
		[sh.title drawAtPoint:p withFont:font];
		current.x += tileSize.width;
		i++;
	}
}

#pragma mark touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	touchesMoved = NO;
	UITouch *touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];
	int i = floor(p.x/tileSize.width);
	if (i >= 0 && i < shortcuts.count) {
		recentlyTouchedItem = i;
		[self setNeedsDisplay];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	recentlyTouchedItem = -1;
	[self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	touchesMoved = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!touchesMoved) {
		UITouch *touch = [touches anyObject];
		CGPoint p = [touch locationInView:self];
		int i = floor(p.x/tileSize.width);
		if (i >= 0 && i < shortcuts.count) {
			Shortcut *sh = [shortcuts objectAtIndex:i];
			[sh invoke];
		}
	}
	recentlyTouchedItem = -1;
	[self setNeedsDisplay];
}

- (void)dealloc {
    [super dealloc];
}


@end

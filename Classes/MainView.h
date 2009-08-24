//
//  MainView.h
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

#import <UIKit/UIKit.h>

#import "hack.h"

#define kKeyTileSize (@"tileSize")

@class MainViewController, TilePosition, Window, TileSet, ShortcutView;

@interface MainView : UIView {

	MainViewController *mainViewController;
	UIFont *statusFont;
	CGSize tileSize;
	CGSize maxTileSize;
	CGSize minTileSize;
	CGPoint start;
	IBOutlet UITextField *dummyTextField;

	BOOL tiled;
	TileSet *tileSet;
	
	CGPoint offset;
	ShortcutView *shortcutView;
	
	UIImage *petMark;
	
	NSMutableArray *messageLabels;

}

@property (nonatomic, readonly) CGPoint start;
@property (nonatomic, readonly) CGSize tileSize;
@property (nonatomic, readonly) IBOutlet UITextField *dummyTextField;
@property (nonatomic, readonly) BOOL isMoved;
@property (nonatomic, readonly) TileSet *tileSet;

- (void) drawTiledMap:(Window *)map inContext:(CGContextRef)ctx clipRect:(CGRect)clipRect;
- (UIFont *) fontAndSize:(CGSize *)size forStrings:(NSArray *)strings withFont:(UIFont *)font;
- (UIFont *) fontAndSize:(CGSize *)size forString:(NSString *)s withFont:(UIFont *)font;
- (TilePosition *) tilePositionFromPoint:(CGPoint)p;
- (void) moveAlongVector:(CGPoint)d;
- (void) resetOffset;
- (void) zoom:(CGFloat)d;

@end

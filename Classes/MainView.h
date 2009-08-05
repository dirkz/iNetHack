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

@class MainViewController, TilePosition, Window, TiledImages, ShortcutView;

@interface MainView : UIView {

	MainViewController *mainViewController;
	UIFont *statusFont;
	UIFont *flashMessageFont;
	CGSize tileSize;
	CGSize maxTileSize;
	CGSize minTileSize;
	CGPoint start;
	IBOutlet UITextField *dummyTextField;

	BOOL tiled;
	TiledImages *images;
	
	CGPoint offset;
	ShortcutView *shortcutView;
	ShortcutView *shortcutViewBottom;

}

@property (nonatomic, readonly) CGPoint start;
@property (nonatomic, readonly) CGSize tileSize;
@property (nonatomic, readonly) IBOutlet UITextField *dummyTextField;

- (void) drawTiledMap:(Window *)map inContext:(CGContextRef)ctx;
- (UIFont *) fontAndSize:(CGSize *)size forStrings:(NSArray *)strings withFont:(UIFont *)font;
- (TilePosition *) tilePositionFromPoint:(CGPoint)p;
- (void) moveAlongVector:(CGPoint)d;
- (void) resetOffset;
- (void) zoom:(CGFloat)d;

@end

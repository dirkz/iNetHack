//
//  MainViewController.h
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

#include "hack.h"

// ctrl-macro
#ifndef C
#define C(c)		(0x1f & (c))
#endif

#define kMinimumPinchDelta (15)

@class Window, MenuViewController, NethackMenuViewController, NethackYnFunction, TextInputViewController, NethackEventQueue;
@class DirectionInputViewController, ExtendedCommandViewController;
@class TouchInfo, TouchInfoStore;
@class TilePosition;
@class NetHackMenuInfo;
@class DMath;

@interface MainViewController : UIViewController <UIActionSheetDelegate, UITextFieldDelegate> {
	
	IBOutlet MenuViewController *menuViewController;
	IBOutlet NethackMenuViewController *nethackMenuViewController;
	IBOutlet TextInputViewController *textInputViewController;
	IBOutlet DirectionInputViewController *directionInputViewController;
	IBOutlet ExtendedCommandViewController *extendedCommandViewController;
	
	NSMutableArray *windows;
	TilePosition *clip;
	
	NethackEventQueue *nethackEventQueue;
	
	NethackYnFunction *currentYnFunction;
	
	NSCondition *textInputCondition;
	NSCondition *uiCondition;
	
	// imaginary rect for bringing up the main menu
	CGRect tapRect;
	
	CGFloat initialDistance;
	
	TouchInfoStore *touchInfoStore;
	
	TilePosition *lastSingleTapDelta;
	
	NetHackMenuInfo *nethackMenuInfo;
	
	DMath *dmath;
	
	BOOL roleSelectionInProgress;
}

@property (nonatomic, readonly) NSArray *windows;
@property (nonatomic, readonly) TilePosition *clip;
@property (nonatomic, readonly) Window *mapWindow;
@property (nonatomic, readonly) Window *messageWindow;
@property (nonatomic, readonly) Window *statusWindow;
@property (nonatomic, retain) NethackEventQueue *nethackEventQueue;
@property (nonatomic, retain) NetHackMenuInfo *nethackMenuInfo;
@property (nonatomic, assign) BOOL roleSelectionInProgress;

+ (id) instance;
+ (void) message:(NSString *)format, ...;

- (void) mainNethackLoop:(id)arg;
- (winid) createWindow:(int)type;
- (void) destroyWindow:(winid)wid;
- (Window *) windowWithId:(winid)wid;
- (void) displayWindowId:(winid)wid blocking:(BOOL)blocking;
- (void) displayMessage:(Window *)w;

- (void) displayMenuWindow:(Window *)w;
- (void) displayMenuWindowOnUIThread:(Window *)w;

- (void) displayYnQuestion:(NethackYnFunction *)yn;
- (void) displayYnQuestionOnUIThread:(NethackYnFunction *)yn;

- (void) getLine:(char *)line prompt:(const char *)prompt;
- (void) getLineOnUIThread:(NSString *)s;

- (void) broadcastUIEvent;
- (void) broadcastCondition:(NSCondition *)condition;
- (void) waitForCondition:(NSCondition *)condition;

// 0 means cancel, blocking
- (char) getDirectionInput;
- (void) showDirectionInputView:(id)obj;

- (void) nethackKeyboard:(id)i;
- (int) getExtendedCommand;

- (void) doPlayerSelection;

- (void) displayFile:(NSString *)filename mustExist:(BOOL)e;

@end

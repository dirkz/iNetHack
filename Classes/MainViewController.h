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

#import <UIKit/UIKit.h>

#include "hack.h"

// ctrl-macro
#ifndef C
#define C(c)		(0x1f & (c))
#endif

#define kMinimumPinchDelta (15)

#define kOptionUsername (@"username")
#define kOptionAutopickup (@"autopickup")
#define kOptionPickupTypes (@"pickupTypes")

@class Window, MenuViewController, NethackMenuViewController, NethackYnFunction, TextInputViewController, NethackEventQueue;
@class DirectionInputViewController, ExtendedCommandViewController, RoleSelectionViewController;
@class TextDisplayViewController, CreditsViewController;

@interface MainViewController : UIViewController <UIActionSheetDelegate, UITextFieldDelegate> {
	
	IBOutlet MenuViewController *menuViewController;
	IBOutlet NethackMenuViewController *nethackMenuViewController;
	IBOutlet TextInputViewController *textInputViewController;
	IBOutlet DirectionInputViewController *directionInputViewController;
	IBOutlet ExtendedCommandViewController *extendedCommandViewController;
	IBOutlet RoleSelectionViewController *roleSelectionViewController;
	IBOutlet TextDisplayViewController *textDisplayViewController;
	IBOutlet CreditsViewController *creditsViewController;
	
	NSMutableArray *windows;
	int clipx;
	int clipy;
	
	NethackEventQueue *nethackEventQueue;
	
	UITouch *lastSingleTouch;
	BOOL touchesMoved;
	BOOL moving;
	NethackYnFunction *currentYnFunction;
	
	NSString *prompt;
	
	NSCondition *textInputCondition;
	NSCondition *uiCondition;
	NSCondition *textDisplayCondition;
	
	// moving the map
	CGPoint currentTouchLocation;
	
	// imaginary rect for bringing up the main menu
	CGRect tapRect;
	
	BOOL longMoveOccurred;

}

@property (nonatomic, readonly) NSArray *windows;
@property (nonatomic, assign) int clipx;
@property (nonatomic, assign) int clipy;
@property (nonatomic, readonly) Window *mapWindow;
@property (nonatomic, readonly) Window *messageWindow;
@property (nonatomic, readonly) Window *statusWindow;
@property (nonatomic, retain) NSString *prompt;
@property (nonatomic, retain) NethackEventQueue *nethackEventQueue;
@property (nonatomic, readonly) BOOL moving;

+ (id) instance;
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

- (char) directionFromNormalizedVector:(CGPoint)d;

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
- (NSString *) askName;

- (void) displayFile:(NSString *)filename mustExist:(BOOL)e;

- (void) initOptions;
- (void) overrideOptions;

@end

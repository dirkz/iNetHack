//
//  iNethackAppDelegate.m
//  iNetHack
//
//  Created by dirk on 6/16/09.
//  Copyright Dirk Zimmermann 2009. All rights reserved.
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

#import "iNethackAppDelegate.h"
#import "MainViewController.h"
#import "NethackEventQueue.h"
#import "MainView.h"
#import "MainMenuViewController.h"

#include "hack.h"

@implementation iNethackAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	[application setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	
	// use mainNavigationController.view to skip main menu
	[window addSubview:mainNavigationController.view];
	//[window addSubview:mainMenuViewController.view];

    [window makeKeyAndVisible];
	[application setStatusBarHidden:YES animated:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[[NSUserDefaults standardUserDefaults] setFloat:[(MainView *) [[MainViewController instance] view] tileSize].width
											 forKey:kKeyTileSize];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	if ([[MainViewController instance] gameInProgress]) {
		dosave();
	} else {
		int fail = unlink(lock);
		NSCAssert1(!fail, @"Failed to unlink lock %s", lock);
	}
}

- (void)dealloc {
    [window release];
    [super dealloc];
}


@end

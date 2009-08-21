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

#include "hack.h"

@implementation iNethackAppDelegate

@synthesize window;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    

    // Override point for customization after application launch
	[window addSubview:mainNavigationController.view];
    [window makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[[NSUserDefaults standardUserDefaults] setFloat:[(MainView *) [[MainViewController instance] view] tileSize].width
											 forKey:kKeyTileSize];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	if (![[MainViewController instance] roleSelectionInProgress]) {
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

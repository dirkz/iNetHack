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
#import "Hearse.h"

#include "hack.h"

@implementation iNethackAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	[self createNetHackDirectories];
	
	[application setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	
#ifndef HEARSE_ONLY
	// use mainNavigationController.view to skip main menu
	[window addSubview:mainNavigationController.view];
	//[window addSubview:mainMenuViewController.view];
#endif

    [window makeKeyAndVisible];
	[application setStatusBarHidden:YES animated:YES];
	
	// don't use hearse in the sim, bones are incompatible!
#if !TARGET_IPHONE_SIMULATOR && !defined(HEARSE_DISABLE)
	[Hearse start];
#endif
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[Hearse stop];
	
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

- (void) createNetHackDirectories {
	// create save directory
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *saveDirectory = [paths lastObject];
	saveDirectory = [saveDirectory stringByAppendingPathComponent:@"nethack"];
	NSString *currentDirectory = [NSString stringWithString:saveDirectory];
	saveDirectory = [saveDirectory stringByAppendingPathComponent:@"save"];
	NSLog(@"saveDirectory %@", saveDirectory);
	if (![[NSFileManager defaultManager] fileExistsAtPath:saveDirectory]) {
		BOOL succ = [[NSFileManager defaultManager] createDirectoryAtPath:saveDirectory withIntermediateDirectories:YES
															   attributes:nil error:nil];
		if (!succ) {
			NSLog(@"saveDirectory could not be created!");
		}
	}
	[[NSFileManager defaultManager] changeCurrentDirectoryPath:currentDirectory];
	NSArray *filelist = [[NSFileManager defaultManager] directoryContentsAtPath:saveDirectory];
	NSLog(@"files in save directory");
	for (NSString *filename in filelist) {
		NSLog(@"file %@", filename);
	}
	filelist = [[NSFileManager defaultManager] directoryContentsAtPath:@"."];
	NSLog(@"files in current directory %@", currentDirectory);
	for (NSString *filename in filelist) {
		NSLog(@"file %@", filename);
	}
}

- (void)dealloc {
    [window release];
    [super dealloc];
}

@end

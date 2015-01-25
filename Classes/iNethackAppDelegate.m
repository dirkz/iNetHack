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
#import "FileLogger.h"

#define kBonesFilename (@"filename")
#define kBonesMd5 (@"md5")

@implementation iNethackAppDelegate

@synthesize window;

- (void) loggingTest {
	NSString *tmpFile = [FileLogger tmpFileName];
	NSLog(@"tmpFile %@", tmpFile);
	for (int i = 0; i < 500; ++i) {
		FileLogger *logger = [[FileLogger alloc] initWithFile:tmpFile maxSize:250];
		for (int j = 0; j < 1000; ++j) {
			[logger logString:[NSString stringWithFormat:@"This is some logged line #%04d", j]];
		}
		[logger release];
	}
	[[NSFileManager defaultManager] removeItemAtPath:tmpFile error:NULL];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
//	[self loggingTest];
//	return;

	BOOL badBonesSeen = [self checkNetHackDirectories];

    [application setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO]; // prevent start orientation bug
    [application setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];

    // use mainNavigationController.view to skip main menu

    //iNethack2 commented out below, added line after, to get rid of "Application windows are expected to have a root view controller at the end of application launch" message
    //	[window addSubview:mainNavigationController.view];
    [self.window setRootViewController:mainNavigationController];

    //[window addSubview:mainMenuViewController.view];
    [window makeKeyAndVisible];
    self.window.frame = [UIScreen mainScreen].bounds; //iNethack2

    [application setStatusBarHidden:YES];
	
	if (!badBonesSeen) {
		[self launchNetHack];
		[self launchHearse];
	}
}

/*
//--iNethack2: Since applicationWillTerminate rarely (if ever) is called, we check for app in background to initiate saving your game
    Only downside is it exits the game, but don't see a real way around it.
 */
- (void) applicationDidEnterBackground:(UIApplication *)application {
    return [self applicationWillTerminate:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[Hearse stop];
	
	[[NSUserDefaults standardUserDefaults] setFloat:[(MainView *) [[MainViewController instance] view] tileSize].width
											 forKey:kKeyTileSize];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	if ([[MainViewController instance] gameInProgress]) {
		dosave();
	} else {
		NSString *lockFile = [NSString stringWithCString:lock encoding:NSASCIIStringEncoding];
		if ([[NSFileManager defaultManager] fileExistsAtPath:lockFile]) {
			int fail = unlink(lock);
			NSCAssert1(!fail, @"Failed to unlink lock %s", lock);
		}
	}
}

- (void) launchNetHack {
#ifndef HEARSE_ONLY
	[[MainViewController instance] performSelectorOnMainThread:@selector(launchNetHack)
													withObject:nil waitUntilDone:NO];
#endif
}

- (void) launchHearse {
#if !defined(HEARSE_DISABLE)
	[Hearse start];
#endif
}

- (void) createTestBadBonesFile {
	NSString *bones = @"./bonD0.1"; //iNethack2 -- added "./" to path
	[@"contents of bad bones file" writeToFile:bones atomically:NO encoding:NSASCIIStringEncoding error:NULL];
	NSString *md5Bones = [Hearse md5HexForFile:bones];
	[md5Bones writeToFile:@"./bonD0.1.bad" atomically:NO encoding:NSASCIIStringEncoding error:NULL]; //iNethack2 -- added "./"
}

- (BOOL) checkNetHackDirectories {
	BOOL badBonesSeen = NO;
	static NSString *const suffix = @".bad";
	static const int suffixLength = 4;
	badBones = [[NSMutableArray alloc] init];
	NSError *error = nil;
	
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

    NSArray *filelist= [[NSFileManager defaultManager]  contentsOfDirectoryAtPath:saveDirectory error:nil];
    
	NSLog(@"files in save directory");
	for (NSString *filename in filelist) {
		NSLog(@"file %@", filename);
	}

	// simple test case for UI interaction with bad bones
	//[self createTestBadBonesFile];
	
    filelist= [[NSFileManager defaultManager]  contentsOfDirectoryAtPath:@"." error:nil];
    
	NSLog(@"files in current directory %@", currentDirectory);
	for (NSString *file in filelist) {
		NSLog(@"file %@", file);
		NSRange r = [file rangeOfString:suffix];
		if (r.location != NSNotFound && r.location == file.length-suffixLength) {
			NSString *bones = [file stringByReplacingCharactersInRange:r withString:@""];
			if ([[NSFileManager defaultManager] fileExistsAtPath:bones]) {
				NSString *md5Bad = [NSString stringWithContentsOfFile:file encoding:NSASCIIStringEncoding error:NULL];
				NSString *md5Bones = [Hearse md5HexForFile:bones];
				if ([md5Bad isEqual:md5Bones]) {
					NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:bones, kBonesFilename,
									   md5Bad, kBonesMd5, nil];
					[badBones addObject:d];
					[[NSFileManager defaultManager] removeItemAtPath:bones error:&error];
					[[NSFileManager defaultManager] removeItemAtPath:file error:&error];
				}
			}
		}
	}
	if (badBones.count > 0) {
		badBonesSeen = YES;
		NSString *message = @"There have been bad bones detected and removed.";
		message = [message stringByAppendingString:@"Please mail them to the Hearse team now."];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bad Bones" message:message
													   delegate:self cancelButtonTitle:@"Mail"
											  otherButtonTitles:@"Play", nil];
		[alert show];
	}
	return badBonesSeen;
}

- (void) mailBadBones {
	NSString *recipients = @"mailto:nethackhearse@gmail.com?cc=me@dirkz.com&subject=Bad bones files";
	NSString *body = @"&body=\n";
	for (NSDictionary *d in badBones) {
		body = [body stringByAppendingFormat:@"File: %@ md5: %@\n",
				[d objectForKey:kBonesFilename], [d objectForKey:kBonesMd5]];
	}
	
	NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
	email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		[self mailBadBones];
	} else {
		[self launchNetHack];
		[self launchHearse];
	}
	[badBones release];
}

- (void)dealloc {
    [window release];
    [super dealloc];
}

@end

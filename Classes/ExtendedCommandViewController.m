//
//  ExtendedCommandViewController.m
//  iNetHack
//
//  Created by dirk on 7/6/09.
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

#import "ExtendedCommandViewController.h"
#import "MainViewController.h"
#include "hack.h"
#include "func_tab.h"

@implementation ExtendedCommandViewController

@synthesize result;


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	result = -1;
	UITableView *tv = (UITableView *) self.view;
	tv.backgroundColor = [UIColor blackColor];
    tv.separatorStyle = UITableViewCellSeparatorStyleNone;
    //iNethack2: Update iOS9: this scrolling fix no longer needed. Commenting out.
    /*
    long bottom;
    bottom= (self.view.frame.size.height + self.view.frame.origin.y) - [ExtendedCommandViewController screenSize].height;
    [tv setContentInset:UIEdgeInsetsMake(0, 0, bottom, 0)];
     */
}

- (void)viewWillDisappear:(BOOL)animated {
	if (result == -1) {
		[[MainViewController instance] broadcastUIEvent];
	}
}

//iNethack2: screenSize that works with both iOS7 + 8
+ (CGSize)screenSize {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        return CGSizeMake(screenSize.height, screenSize.width);
    }
    return screenSize;
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	int row = (int) [indexPath row];
	result = row;
	[[MainViewController instance] broadcastUIEvent];
	[self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	[self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark UITableView datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	struct ext_func_tab *f = extcmdlist;
	int c = 0;
	while (f++->ef_txt) {
		c++;
	}
	return c;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellId = @"extendedCommandViewControllerCellId";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
	if (!cell) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero] autorelease];
		cell.backgroundColor = [UIColor blackColor];
		cell.textLabel.textColor = [UIColor whiteColor];
	}
	int row = (int) [indexPath row];
	cell.textLabel.text = [[NSString stringWithCString:extcmdlist[row].ef_txt encoding:NSASCIIStringEncoding] capitalizedString];
	cell.accessoryType = UITableViewCellAccessoryNone;
	return cell;
}

- (void)dealloc {
    [super dealloc];
}


@end

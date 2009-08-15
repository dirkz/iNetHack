//
//  NethackMenuViewController.m
//  iNetHack
//
//  Created by dirk on 6/30/09.
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

#import "NethackMenuViewController.h"
#import "Window.h"
#import "NethackMenuItem.h"
#import "MainViewController.h"
#import "NetHackMenuInfo.h"
#import "NetHackMenuInfo.h"
#import "MainView.h"
#import "TiledImages.h"
#import "NSString+Regexp.h"

extern short glyph2tile[];

@implementation NethackMenuViewController

@synthesize menuWindow;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}

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

- (void) setMenuWindow:(Window *)w {
	menuWindow = w;
	menuWindow.menuResult = kMenuCancelled;
	if (w.menuPrompt && w.menuPrompt.length > 0) {
		self.title = w.menuPrompt;
	} else if ([[MainViewController instance] nethackMenuInfo]) {
		self.title = [[[MainViewController instance] nethackMenuInfo] prompt];
		NetHackMenuInfo *nethackMenuInfo = [[MainViewController instance] nethackMenuInfo];
		if (nethackMenuInfo) {
			// extend menu items
			if (nethackMenuInfo.acceptBareHanded || nethackMenuInfo.acceptMoney || nethackMenuInfo.acceptMore) {
				anything any;
				any.a_int = 0;
				NethackMenuItem *miParent = [[NethackMenuItem alloc] initWithId:&any title:"Meta" glyph:kNoGlyph
																	preselected:NO];
				[menuWindow addMenuItem:miParent];
				[miParent release];
				if (nethackMenuInfo.acceptBareHanded) {
					any.a_int = '-';
					NethackMenuItem *mi = [[NethackMenuItem alloc] initWithId:&any title:"Hands (-)" glyph:kNoGlyph
																  preselected:NO];
					[menuWindow addMenuItem:mi];
					[mi release];
				}
				if (nethackMenuInfo.acceptMore) {
					any.a_int = '*';
					NethackMenuItem *mi = [[NethackMenuItem alloc] initWithId:&any title:"More (*)" glyph:kNoGlyph
																  preselected:NO];
					[menuWindow addMenuItem:mi];
					[mi release];
				}
				if (nethackMenuInfo.acceptMoney) {
					any.a_int = '$';
					NethackMenuItem *mi = [[NethackMenuItem alloc] initWithId:&any title:"Gold ($)" glyph:kNoGlyph
																  preselected:NO];
					[menuWindow addMenuItem:mi];
					[mi release];
				}
			}
		}
	} else {
		self.title = @"Menu";
	}
	// first time we are here tf is nil, later it gets set, which works fine
	[tf reloadData];
}

- (void) collectSelectedItems:(NSArray *)menuItems into:(NSMutableArray *)items {
	for (NethackMenuItem *i in menuItems) {
		if (i.isTitle) {
			[self collectSelectedItems:i.children into:items];
		} else {
			if (i.isSelected) {
				[items addObject:i];
			}
		}
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if (menuWindow.menuHow == PICK_ANY) {
		NSMutableArray *items = [NSMutableArray array];
		[self collectSelectedItems:menuWindow.menuItems into:items];
		menuWindow.menuResult = items.count;
		menuWindow.menuList = malloc(sizeof(menu_item) * items.count);
		for (int i = 0; i < items.count; ++i) {
			NethackMenuItem *item = [items objectAtIndex:i];
			menuWindow.menuList[i].count = -1;
			menuWindow.menuList[i].item = item.identifier;
		}
	}
	[[MainViewController instance] broadcastUIEvent];
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	int row = [indexPath row];
	int section = [indexPath section];
	NethackMenuItem *i = nil;
	if (menuWindow.isShallowMenu) {
		if (section != 0) {
			NSLog(@"error in %s: section number in shallow menu!", __FUNCTION__);
		}
		i = [menuWindow.menuItems objectAtIndex:row];
	} else {
		i = [menuWindow.menuItems objectAtIndex:section];
		i = [i.children objectAtIndex:row];
	}
	if (menuWindow.menuHow == PICK_ANY) {
		i.isSelected = !i.isSelected;
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		cell.accessoryType = i.isSelected ? UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
	} else {
		menuWindow.menuResult = 1;
		menuWindow.menuList = malloc(sizeof(menu_item));
		menuWindow.menuList->count = -1;
		menuWindow.menuList->item = i.identifier;
		[self.navigationController popToRootViewControllerAnimated:NO];
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	[self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark UITableView datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	tf = tableView;
	if (menuWindow.isShallowMenu) {
		return 1;
	} else {
		return menuWindow.menuItems.count;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (menuWindow.isShallowMenu) {
		if (section != 0) {
			NSLog(@"error in %s: section number in shallow menu!", __FUNCTION__);
		}
		return menuWindow.menuItems.count;
	} else {
		NethackMenuItem *i = [menuWindow.menuItems objectAtIndex:section];
		return i.children.count;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NethackMenuItem *i = [menuWindow.menuItems objectAtIndex:section];
	return i.title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static int kTagImageView = 1;
	static int kTagTextLabel = 2;
	static int kTagDetailTextLabel = 3;
	static NSString *cellId = @"nethackMenuViewControllerCellId";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
	if (!cell) {
#ifdef IPHONE_OS_3.0
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId] autorelease];
#else
		CGFloat width = self.view.frame.size.width;
		CGFloat height = 44; // standard cell height
		CGRect cellRect = CGRectMake(0, 0, width, height);
		cell = [[[UITableViewCell alloc] initWithFrame:cellRect reuseIdentifier:cellId] autorelease];
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
		imageView.tag = kTagImageView;
		[cell addSubview:imageView];
		[imageView release];
		UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 0, width, 22)];
		textLabel.font = [UIFont boldSystemFontOfSize:14];
		textLabel.tag = kTagTextLabel;
		[cell addSubview:textLabel];
		[textLabel release];
		UILabel *detailTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, textLabel.frame.size.height, width, 15)];
		detailTextLabel.font = [UIFont systemFontOfSize:12];
		detailTextLabel.tag = kTagDetailTextLabel;
		[cell addSubview:detailTextLabel];
		[detailTextLabel release];
#endif
	}
	int row = [indexPath row];
	int section = [indexPath section];
	NethackMenuItem *i = nil;
	if (menuWindow.isShallowMenu) {
		if (section != 0) {
			NSLog(@"error in %s: section number in shallow menu!", __FUNCTION__);
		}
		i = [menuWindow.menuItems objectAtIndex:row];
	} else {
		i = [menuWindow.menuItems objectAtIndex:section];
		i = [i.children objectAtIndex:row];
	}

	//cell.imageView.image = uiImg;
	UIImageView *imageView = (UIImageView *) [cell viewWithTag:kTagImageView];
	if (i.glyph != NO_GLYPH && i.glyph != kNoGlyph) {
		MainView *view = (MainView *) [[MainViewController instance] view];
		int t = glyph2tile[i.glyph];
		CGImageRef img = [view.images imageAt:t];
		UIImage *uiImg = [UIImage imageWithCGImage:img];
		imageView.image = uiImg;
	} else {
		imageView.image = nil;
	}
	
	NSArray *strings;
	NSString *ws = [i.title substringBetweenDelimiters:@"()"];
	if (ws && ws.length > 1) {
		NSRange r = [i.title rangeOfString:ws];
		strings = [NSArray arrayWithObjects:[i.title substringToIndex:r.location-2], ws, nil];
	} else {
		strings = [NSArray arrayWithObjects:i.title, nil];
	}
	
#ifdef IPHONE_OS_3.0
	UILabel *textLabel = cell.textLabel;
	UILabel *detailTextLabel = cell.detailTextLabel;
#else
	UILabel *textLabel = (UILabel *) [cell viewWithTag:kTagTextLabel];
	UILabel *detailTextLabel = (UILabel *) [cell viewWithTag:kTagDetailTextLabel];
#endif
	textLabel.text = [strings objectAtIndex:0];
	if (strings.count == 2) {
		detailTextLabel.text = [strings objectAtIndex:1];
	} else {
		detailTextLabel.text = nil;
	}
	
	cell.accessoryType = i.isSelected ? UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
	return cell;
}

- (void)dealloc {
    [super dealloc];
}

@end

//
//  ItemAmountViewController.m
//  iNetHack
//
//  Created by dirk on 8/22/09.
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

#import "ItemAmountViewController.h"
#import "NethackMenuItem.h"
#import "MainViewController.h"
#import "Window.h"
#import "TileSet.h"
#import "NSString+NetHack.h"

extern short glyph2tile[];

@implementation ItemAmountViewController

@synthesize menuWindow;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
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

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Set Amount";
	amountSlider.continuous = YES;
	[amountSlider addTarget:self action:@selector(sliderValueHasChanged:) forControlEvents:UIControlEventValueChanged];
	[dropButton addTarget:self action:@selector(finishPickOne:) forControlEvents:UIControlEventTouchUpInside];
}

- (void) sliderValueHasChanged:(id)sender {
	UISlider *slider = (UISlider *) sender;
	int v = round(slider.value);
	amountTextLabel.text = [NSString stringWithFormat:@"%d", v];
	if (v > 0) {
		menuWindow.nethackMenuItem.amount = v;
	} else {
		menuWindow.nethackMenuItem.amount = -1;
	}
}

- (void) finishPickOne:(id)sender {
	NethackMenuItem *i = menuWindow.nethackMenuItem;
	menuWindow.menuResult = 1;
	menuWindow.menuList = malloc(sizeof(menu_item));
	menuWindow.menuList->count = i.amount;
	menuWindow.menuList->item = i.identifier;
	[self.navigationController popToRootViewControllerAnimated:NO];
	[[MainViewController instance] broadcastUIEvent];
}

- (void)viewWillAppear:(BOOL)animated {
	/*
	UIBarButtonItem *bi = [[UIBarButtonItem alloc] initWithTitle:@"Drop" style:UIBarButtonItemStylePlain
														  target:self action:@selector(finishPickOne:)];
	self.navigationItem.rightBarButtonItem = bi;
	 [bi release];
	*/
	if (menuWindow.nethackMenuItem.glyph != NO_GLYPH && menuWindow.nethackMenuItem.glyph != kNoGlyph) {
		UIImage *uiImg = [UIImage imageWithCGImage:[[TileSet instance] imageForGlyph:menuWindow.nethackMenuItem.glyph]];
		imageView.image = uiImg;
	} else {
		imageView.image = nil;
	}
	NSArray *descriptions = [menuWindow.nethackMenuItem.title splitNetHackDetails];
	itemTextLabel.text = [descriptions objectAtIndex:0];
	if (descriptions.count >= 2) {
		itemDetailTextLabel.text = [descriptions objectAtIndex:1];
	} else {
		itemDetailTextLabel.text = nil;
	}
	int amount = [menuWindow.nethackMenuItem.title parseNetHackAmount];
	amountTextLabel.text = [NSString stringWithFormat:@"%d", amount];
	amountSlider.minimumValue = 0;
	amountSlider.maximumValue = amount;
	amountSlider.value = amount;
}

- (void)dealloc {
    [super dealloc];
}


@end

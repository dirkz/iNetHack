//
//  TextInputViewController.m
//  iNetHack
//
//  Created by dirk on 7/3/09.
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

#import "TextInputViewController.h"
#import "MainViewController.h"

@implementation TextInputViewController

@synthesize prompt, text, numerical, callOnSuccess, condition;

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

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

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
	returned = NO;
	label.text = self.prompt;
	tf.text = self.text;
	if (numerical) {
		tf.keyboardType = UIKeyboardTypeNumberPad;
	}
	[tf becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if (!returned && condition) {
		[condition lock];
		[condition broadcast];
		[condition unlock];
	}
	self.numerical = NO;
	self.callOnSuccess = nil;
	self.condition = nil;
	self.condition = nil;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	returned = YES;
	self.text = tf.text;
	[tf resignFirstResponder];
	[self.navigationController popToRootViewControllerAnimated:NO];
	if (condition) {
		[condition lock];
		[condition broadcast];
		[condition unlock];
	}
	if (callOnSuccess) {
		[callOnSuccess setArgument:&tf atIndex:2];
		[callOnSuccess invoke];
		self.callOnSuccess = nil;
	}
	return YES;
}

- (void)dealloc {
    [super dealloc];
}

@end

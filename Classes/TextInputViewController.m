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

@synthesize prompt, text, numerical, target, action, condition, returnKeyType;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void) nethackShowLog:(id)sender {
	// save what user has typed so far
	self.text = tf.text;
	reentered++;
	[[MainViewController instance] nethackShowLog:sender];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	returned = NO;
	label.text = self.prompt;
	tf.text = self.text;
	if (numerical) {
		tf.keyboardType = UIKeyboardTypeNumberPad;
	}
	tf.returnKeyType = returnKeyType;
	[tf becomeFirstResponder];
	UIBarButtonItem *bi = [[UIBarButtonItem alloc] initWithTitle:@"Log" style:UIBarButtonItemStylePlain
														  target:self action:@selector(nethackShowLog:)];
	self.navigationItem.rightBarButtonItem = bi;
	[bi release];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if (reentered == 0) {
		if (!returned) {
			self.text = @"\033";
			if (condition) {
				[condition lock];
				[condition broadcast];
				[condition unlock];
			}
		}
		self.numerical = NO;
		self.condition = nil;
	} else {
		reentered--;
	}
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
	if (target) {
		[target performSelector:action withObject:self];
	}
	return YES;
}

- (void)dealloc {
	self.target = nil;
	[super dealloc];
}

@end

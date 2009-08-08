//
//  TextDisplayViewController.m
//  iNetHack
//
//  Created by dirk on 7/10/09.
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

#import "TextDisplayViewController.h"
#import "MainViewController.h"

@implementation TextDisplayViewController
@synthesize text, condition, isHTML;

- (void)dealloc
{
	webView.delegate = nil;
	[webView release];
	[textView release];
	[super dealloc];
}

- (void)updateText {
	if (textView) {
		textView.text = self.text;
	} else if (webView) {
		[webView loadHTMLString:self.text baseURL:nil];
	}
}

- (void)setText:(NSString *)newText {
	if (newText != text) {
		[text release];
		text = [newText copy];
		[self updateText];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if ([[NSArray arrayWithObjects:@"http", @"https", nil] containsObject:request.URL.scheme] && navigationType == UIWebViewNavigationTypeLinkClicked) {
		// Open clicked http links in Safari
		[[UIApplication sharedApplication] openURL:request.URL];
		return NO;
	}
	return YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.isHTML) {
		webView = [[UIWebView alloc] initWithFrame:self.view.frame];
		webView.delegate = self;
		[self.view addSubview:webView];
		[webView release];
	} else {
		textView = [[UITextView alloc] initWithFrame:self.view.frame];
		[self.view addSubview:textView];
		[textView release];
	}
	[self updateText];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if (condition) {
		[[MainViewController instance] broadcastCondition:condition];
	}
}
@end

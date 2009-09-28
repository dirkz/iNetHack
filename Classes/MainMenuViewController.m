//
//  MainMenuViewController.m
//  iNetHack
//
//  Created by dirk on 9/28/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

#import "MainMenuViewController.h"

@implementation MainMenuViewController

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
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
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

- (IBAction) startNewGame:(id)sender {
	UIWindow *window = [[UIApplication sharedApplication] keyWindow];
	[self.view removeFromSuperview];
	[window addSubview:mainNavigationController.view];
}

- (void)dealloc {
    [super dealloc];
}


@end

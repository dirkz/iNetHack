//
//  MainMenuViewController.h
//  iNetHack
//
//  Created by dirk on 9/28/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainMenuViewController : UIViewController {

	IBOutlet UINavigationController *mainNavigationController;

}

- (IBAction) startNewGame:(id)sender;

@end

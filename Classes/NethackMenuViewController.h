//
//  NethackMenuViewController.h
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

#import <UIKit/UIKit.h>

#define kMenuCancelled (-1)

@class Window, NethackMenuItem, ItemAmountViewController;

@interface NethackMenuViewController : UITableViewController {
	
	IBOutlet ItemAmountViewController *itemAmountViewController;
	IBOutlet UITableView *tf;
	
	Window *menuWindow;
	BOOL selectAll;

}

@property (nonatomic, assign) Window *menuWindow;

@end

//
//  TextDisplayViewController.h
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

#import <UIKit/UIKit.h>


@interface TextDisplayViewController : UIViewController <UIWebViewDelegate> {
	UIWebView *webView;
	UITextView *textView;
	NSCondition *condition;
	NSString *text;
	BOOL isHTML;
	BOOL isLog;
}

@property (nonatomic, copy) NSString *text;
@property (assign) BOOL isHTML;
@property (nonatomic, retain) NSCondition *condition;
@property (assign) BOOL isLog;

@end

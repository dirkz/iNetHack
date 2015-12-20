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
}

@property (nonatomic, copy) NSString *text;
@property (assign, getter=isHTML) BOOL HTML;
@property (nonatomic, retain) NSCondition *condition;
@property (assign, getter=isLog) BOOL log;

@end

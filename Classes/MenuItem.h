//
//  MenuItem.h
//  iNetHack
//
//  Created by dirk on 6/29/09.
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

#import <Foundation/Foundation.h>


@interface MenuItem : NSObject {

	NSString *title;
	id target;
	SEL selector;
	BOOL accessory;
	
	NSArray *children;
	char key;
	NSInteger tag;
}

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) BOOL accessory;
@property (nonatomic, retain)   NSArray *children;
@property (nonatomic, readonly) char key;
@property (nonatomic, assign)   NSInteger tag;

+ (id) menuItemWithTitle:(NSString *)n target:(id)t selector:(SEL)s accessory:(BOOL)a;
+ (id) menuItemWithTitle:(NSString *)n children:(NSArray *)ch;
+ (id) menuItemWithTitle:(NSString *)n key:(char)k accessory:(BOOL)a;
+ (id) menuItemWithTitle:(NSString *)n key:(char)k;
- (id) initWithTitle:(NSString *)n target:(id)t selector:(SEL)s accessory:(BOOL)a;
- (id) initWithTitle:(NSString *)n children:(NSArray *)ch;
- (id) initWithTitle:(NSString *)n key:(char)k accessory:(BOOL)a;
- (id) initWithTitle:(NSString *)n key:(char)k;
- (void) invoke;

@end

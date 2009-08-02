//
//  NethackMenuItem.h
//  iNetHack
//
//  Created by dirk on 6/29/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

//  This file is part of iNetHack.
//
//  iNetHack is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  iNetHack is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with iNetHack.  If not, see <http://www.gnu.org/licenses/>.

#import <Foundation/Foundation.h>
#include "hack.h"

@interface NethackMenuItem : NSObject {
	
	anything identifier;
	NSString *title;
	BOOL isTitle;
	NSMutableArray *children;
	BOOL isSelected;

}

@property (nonatomic, readonly) anything identifier;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) BOOL isTitle;
@property (nonatomic, readonly) NSMutableArray *children;
@property (nonatomic, assign) BOOL isSelected;

- (id) initWithId:(const anything *)i title:(const char *)t preselected:(BOOL)p;

@end

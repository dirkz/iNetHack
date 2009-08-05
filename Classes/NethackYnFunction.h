//
//  NethackYnFunction.h
//  iNetHack
//
//  Created by dirk on 7/1/09.
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


@interface NethackYnFunction : NSObject {
	
	const char *question;
	const char *choices;
	char defaultChoice;
	int chosen;

}

@property (nonatomic, readonly) const char *question;
@property (nonatomic, readonly) const char *choices;
@property (nonatomic, readonly) char defaultChoice;
@property (nonatomic, assign) int chosen;
@property (nonatomic, readonly) char choice;

- (id) initWithQuestion:(const char *)q choices:(const char *)ch defaultChoice:(const char)c;

@end

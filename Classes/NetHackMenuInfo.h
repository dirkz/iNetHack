//
//  NetHackMenuInfo.h
//  iNetHack
//
//  Created by dirk on 8/6/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NetHackMenuInfo : NSObject {
	
	NSString *prompt;
	BOOL bareHanded;
	BOOL more;

}

@property (nonatomic, assign) BOOL bareHanded;
@property (nonatomic, assign) BOOL more;
@property (nonatomic, retain) NSString *prompt;

@end

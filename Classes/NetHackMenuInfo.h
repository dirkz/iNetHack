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
	BOOL acceptBareHanded;
	BOOL acceptMore;
	BOOL acceptMoney;

}

@property (nonatomic, retain) NSString *prompt;
@property (nonatomic, assign) BOOL acceptBareHanded;
@property (nonatomic, assign) BOOL acceptMore;
@property (nonatomic, assign) BOOL acceptMoney;

@end

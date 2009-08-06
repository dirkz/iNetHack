//
//  TouchInfo.h
//  iNetHack
//
//  Created by dirk on 8/6/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TouchInfo : NSObject {
	
	BOOL pinched;
	BOOL moved;
	BOOL doubleTap;
	CGPoint initialLocation;
	CGPoint currentLocation;

}

@property (nonatomic, assign) BOOL pinched;
@property (nonatomic, assign) BOOL moved;
@property (nonatomic, assign) BOOL doubleTap;
@property (nonatomic, assign) CGPoint initialLocation;

// only updated on -init, for your own use
@property (nonatomic, assign) CGPoint currentLocation;

- (id) initWithTouch:(UITouch *)t;

@end

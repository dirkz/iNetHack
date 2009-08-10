//
//  DMath.h
//  iNetHack
//
//  Created by dirk on 8/10/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _dmathdirection { kUp, kUpRight, kRight, kDownRight, kDown, kDownLeft, kLeft, kUpLeft } dmathdirection;

@interface DMath : NSObject {

	float stdDistance;
	CGPoint directions[8];

}

+ (CGPoint) normalizedPoint:(CGPoint)ps;

// p must be normalized cartesian
- (dmathdirection) directionFromVector:(CGPoint)p;

@end

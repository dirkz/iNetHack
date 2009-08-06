//
//  TouchInfoStore.h
//  iNetHack
//
//  Created by dirk on 8/6/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TouchInfo;

@interface TouchInfoStore : NSObject {
	
	NSMutableDictionary *currentTouchInfos;

}

@property (nonatomic, readonly) int count;

- (void) storeTouches:(NSSet *)touches;
- (TouchInfo *) touchInfoForTouch:(UITouch *)t;
- (void) removeTouches:(NSSet *)touches;

@end

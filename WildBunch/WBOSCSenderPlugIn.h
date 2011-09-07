//
//  WBOSCSenderPlugIn.h
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 6 Sept 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface WBOSCSenderPlugIn : QCPlugIn
@property (nonatomic, retain) NSString* inputHost;
@property (nonatomic) NSUInteger inputPort;
@property (nonatomic, retain) NSString* inputAddress;
@end

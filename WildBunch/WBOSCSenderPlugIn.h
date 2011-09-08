//
//  WBOSCSenderPlugIn.h
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 6 Sept 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface WBOSCSenderPlugIn : QCPlugIn
@property (nonatomic, strong) NSString* inputHost;
@property (nonatomic) NSUInteger inputPort;
@property (nonatomic) BOOL inputSendSignal;
@property (nonatomic, strong) NSString* inputAddress;
@property (nonatomic, strong) NSString* inputTypes;
@end

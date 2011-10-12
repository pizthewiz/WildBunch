//
//  WBOSCReceiverPlugIn.h
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 09 Oct 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface WBOSCReceiverPlugIn : QCPlugIn <PEOSCReceiverDelegate>
@property (nonatomic) NSUInteger inputPort;
@property (nonatomic, weak) NSArray* outputMessage;
@property (nonatomic, weak) NSString* outputMessageAddress;
@property (nonatomic) BOOL outputMessageReceived;
@end

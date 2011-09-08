//
//  WBOSCSenderPlugIn.h
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 6 Sept 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import <Quartz/Quartz.h>

// NB - probably should have just used a dictionary
@interface WBMessageElement : NSObject <NSCoding>
+ (id)messageElementWithType:(NSString*)type portKey:(NSString*)portKey;
- (id)initWithType:(NSString*)type portKey:(NSString*)portKey;
@property (nonatomic, strong) NSString* type;
@property (nonatomic, strong) NSString* portKey;
@end

@interface WBOSCSenderPlugIn : QCPlugIn
@property (nonatomic, strong) NSString* inputHost;
@property (nonatomic) NSUInteger inputPort;
@property (nonatomic) BOOL inputSendSignal;
@property (nonatomic, strong) NSString* inputAddress;
@end

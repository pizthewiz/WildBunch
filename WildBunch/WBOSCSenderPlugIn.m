//
//  WBOSCSenderPlugIn.m
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 6 Sept 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import "WBOSCSenderPlugIn.h"
#import "WildBunch.h"

static NSString* const WBSenderExampleCompositionName = @"";

@interface WBOSCSenderPlugIn()
@property (nonatomic, retain) NSString* host;
@property (nonatomic) NSUInteger port;
@property (nonatomic, retain) PEOSCSender* sender;
- (void)_buildUpSender;
- (void)_tearDownSender;
@end

@implementation WBOSCSenderPlugIn

@dynamic inputHost, inputPort, inputSendSignal, inputAddress;
@synthesize host, port, sender;

+ (NSDictionary*)attributes {
    NSMutableDictionary* attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
        CCLocalizedString(@"WBOSCSenderName", NULL), QCPlugInAttributeNameKey, 
        CCLocalizedString(@"WBOSCSenderDescription", NULL), QCPlugInAttributeDescriptionKey, 
        nil];

#if defined(MAC_OS_X_VERSION_10_7) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_7)
    if (&QCPlugInAttributeCategoriesKey != NULL) {
        // array with category strings
        NSArray* categories = [NSArray arrayWithObjects:@"Network", nil];
        [attributes setObject:categories forKey:QCPlugInAttributeCategoriesKey];
    }
    if (&QCPlugInAttributeExamplesKey != NULL) {
        // array of file paths or urls relative to plugin resources
        NSArray* examples = [NSArray arrayWithObjects:[[NSBundle bundleForClass:[self class]] URLForResource:WBSenderExampleCompositionName withExtension:@"qtz"], nil];
        [attributes setObject:examples forKey:QCPlugInAttributeExamplesKey];
    }
#endif

    return (NSDictionary*)attributes;
}

+ (NSDictionary*)attributesForPropertyPortWithKey:(NSString*)key {
    if ([key isEqualToString:@"inputHost"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Host", QCPortAttributeNameKey, QCPortTypeString, QCPortAttributeTypeKey, @"0.0.0.0", QCPortAttributeDefaultValueKey, nil];
    else if ([key isEqualToString:@"inputPort"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Port", QCPortAttributeNameKey, 
            [NSNumber numberWithUnsignedInteger:0], QCPortAttributeMinimumValueKey, 
            [NSNumber numberWithUnsignedInteger:65536], QCPortAttributeMaximumValueKey, 
            [NSNumber numberWithUnsignedInteger:7777], QCPortAttributeDefaultValueKey, nil];
    else if ([key isEqualToString:@"inputSendSignal"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Send Signal", QCPortAttributeNameKey, nil];
    else if ([key isEqualToString:@"inputAddress"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Address", QCPortAttributeNameKey, QCPortTypeString, QCPortAttributeTypeKey, @"/oscillator/3/frequency", QCPortAttributeDefaultValueKey, nil];
	return nil;
}

+ (QCPlugInExecutionMode)executionMode {
	return kQCPlugInExecutionModeConsumer;
}

+ (QCPlugInTimeMode)timeMode {
	return kQCPlugInTimeModeIdle;
}

#pragma mark - EXECUTION

- (BOOL)startExecution:(id <QCPlugInContext>)context {
	return YES;
}

- (void)enableExecution:(id <QCPlugInContext>)context {
    if (self.host && self.port)
        [self _buildUpSender];
}

- (BOOL)execute:(id <QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments {

    // negotiate new connection
    if ([self didValueForInputKeyChange:@"inputHost"] || [self didValueForInputKeyChange:@"inputPort"]) {
        CCDebugLog(@"host or port changed, will negotiate new connection");

        // store for safe keeping, may be needed in unplug/replug or stop/start
        self.host = self.inputHost;
        self.port = self.inputPort;

        [self _buildUpSender];
    }

    if ([self didValueForInputKeyChange:@"inputSendSignal"] && self.inputSendSignal) {
        NSArray* types = [NSArray arrayWithObject:PEOSCMessageTypeTagImpulse];
        NSArray* args = nil;
        PEOSCMessage* message = [[PEOSCMessage alloc] initWithAddress:self.inputAddress typeTags:types arguments:args];
        [self.sender sendMessage:message];
    }

	return YES;
}

- (void)disableExecution:(id <QCPlugInContext>)context {
    [self _tearDownSender];
}

- (void)stopExecution:(id <QCPlugInContext>)context {
}

#pragma mark - PRIVATE

- (void)_buildUpSender {
    PEOSCSender* s = [[PEOSCSender alloc] initWithHost:self.host port:self.port];
    self.sender = s;
}

- (void)_tearDownSender {
    self.sender = nil;
}

@end

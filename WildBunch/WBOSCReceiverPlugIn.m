//
//  WBOSCReceiverPlugIn.m
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 09 Oct 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import "WBOSCReceiverPlugIn.h"
#import "WildBunch.h"

static NSString* const WBReceiverExampleCompositionName = @"";

@interface WBOSCReceiverPlugIn()
@property (nonatomic) NSUInteger port;
@property (nonatomic, strong) PEOSCReceiver* receiver;
@property (nonatomic, strong) PEOSCMessage* message;
@property (nonatomic) BOOL messageReceived;
@property (nonatomic) BOOL messageReceivedSignalDidChange;
- (void)_buildUpReceiver;
- (void)_tearDownReceiver;
@end

@implementation WBOSCReceiverPlugIn

@dynamic inputPort, outputMessage, outputMessageAddress, outputMessageReceived;
@synthesize port, receiver, message, messageReceived, messageReceivedSignalDidChange;

+ (NSDictionary*)attributes {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys: 
        CCLocalizedString(@"WBOSCReceiverName", NULL), QCPlugInAttributeNameKey, 
        CCLocalizedString(@"WBOSCReceiverDescription", NULL), QCPlugInAttributeDescriptionKey, 
        [NSArray arrayWithObjects:@"Network", nil], QCPlugInAttributeCategoriesKey, 
        [NSArray arrayWithObjects:[CCPlugInBundle() URLForResource:WBReceiverExampleCompositionName withExtension:@"qtz"], nil], QCPlugInAttributeExamplesKey, 
        nil];
}

+ (NSDictionary*)attributesForPropertyPortWithKey:(NSString*)key {
    if ([key isEqualToString:@"inputPort"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Port", QCPortAttributeNameKey, 
            [NSNumber numberWithUnsignedInteger:0], QCPortAttributeMinimumValueKey, 
            [NSNumber numberWithUnsignedInteger:65536], QCPortAttributeMaximumValueKey, 
            [NSNumber numberWithUnsignedInteger:7777], QCPortAttributeDefaultValueKey, 
            nil];
    else if ([key isEqualToString:@"outputMessage"])
        return [NSDictionary dictionaryWithObject:@"Message" forKey:QCPortAttributeNameKey];
    else if ([key isEqualToString:@"outputMessageAddress"])
        return [NSDictionary dictionaryWithObject:@"Message Address" forKey:QCPortAttributeNameKey];
    else if ([key isEqualToString:@"outputMessageReceived"])
        return [NSDictionary dictionaryWithObject:@"Message Received" forKey:QCPortAttributeNameKey];
	return nil;
}

+ (QCPlugInExecutionMode)executionMode {
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode)timeMode {
	return kQCPlugInTimeModeIdle;
}

#pragma mark -

- (void)dealloc {
    [self _tearDownReceiver];
}

#pragma mark - EXECUTION

- (BOOL)startExecution:(id <QCPlugInContext>)context {
	return YES;
}

- (void)enableExecution:(id <QCPlugInContext>)context {
    // setup receiver when possible
    if (self.port) {
        [self _buildUpReceiver];
    }
}

- (BOOL)execute:(id <QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments {
    // update outputs when appropriate
    if (self.messageReceivedSignalDidChange) {
        if (self.messageReceivedSignalDidChange) {
            // cheap dump of args to struct
            __block NSMutableArray* structure = [NSMutableArray array];
            [self.message enumerateTypesAndArgumentsUsingBlock:^(id type, id argument, BOOL *stop) {
                [structure addObject:argument];
            }];
            self.outputMessage = structure;

            self.outputMessageAddress = self.message.address;
        }

        self.outputMessageReceived = self.messageReceived;
        self.messageReceivedSignalDidChange = self.messageReceived;
        self.messageReceived = NO;
    }

    // negotiate new connection
    if ([self didValueForInputKeyChange:@"inputPort"]) {
        CCDebugLog(@"port changed, will negotiate new connection");

        // store for safe keeping, may be needed stop/start
        self.port = self.inputPort;

        [self _buildUpReceiver];
    }

	return YES;
}

- (void)disableExecution:(id <QCPlugInContext>)context {
    [self _tearDownReceiver];
}

- (void)stopExecution:(id <QCPlugInContext>)context {
}

#pragma mark - RECEIVER DELEGATE

- (void)didReceiveMessage:(PEOSCMessage*)m {
    self.message = m;
    self.messageReceived = YES;
    self.messageReceivedSignalDidChange = YES;
}

#pragma mark - PRIVATE

- (void)_buildUpReceiver {
    CCDebugLogSelector();
    if (self.receiver) {
        [self _tearDownReceiver];
    }

    PEOSCReceiver* r = [[PEOSCReceiver alloc] initWithPort:self.port];
    self.receiver = r;
    self.receiver.delegate = self;
    [self.receiver connect];
}

- (void)_tearDownReceiver {
    CCDebugLogSelector();
    if (self.receiver.isConnected)
        [self.receiver disconnect];
    self.receiver = nil;
}

@end

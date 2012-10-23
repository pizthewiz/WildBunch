//
//  WBOSCReceiverPlugIn.m
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 09 Oct 2011.
//  Copyright (c) 2011-2012 Chorded Constructions. All rights reserved.
//

#import "WBOSCReceiverPlugIn.h"
#import "WildBunch.h"

static NSString* const WBReceiverExampleCompositionName = @"Arp OSC Receiver";

@interface WBOSCReceiverPlugIn()
@property (nonatomic) NSUInteger port;
@property (nonatomic, strong) PEOSCReceiver* receiver;
@property (nonatomic, strong) PEOSCMessage* message;
@property (nonatomic) BOOL messageReceived;
@property (nonatomic) BOOL messageReceivedSignalDidChange;
@end

@implementation WBOSCReceiverPlugIn

@dynamic inputPort, outputMessage, outputMessageAddress, outputMessageReceived;

+ (NSDictionary*)attributes {
    return @{
        QCPlugInAttributeNameKey: CCLocalizedString(@"WBOSCReceiverName", NULL),
        QCPlugInAttributeDescriptionKey: CCLocalizedString(@"WBOSCReceiverDescription", NULL),
        QCPlugInAttributeCategoriesKey: @[@"Network"],
//        QCPlugInAttributeExamplesKey: @[[CCPlugInBundle() URLForResource:WBReceiverExampleCompositionName withExtension:@"qtz"]]
    };
}

+ (NSDictionary*)attributesForPropertyPortWithKey:(NSString*)key {
    if ([key isEqualToString:@"inputPort"])
        return @{QCPortAttributeNameKey: @"Port", QCPortAttributeMinimumValueKey: @0, QCPortAttributeMaximumValueKey: @65536, QCPortAttributeDefaultValueKey: @7777};
    else if ([key isEqualToString:@"outputMessage"])
        return @{QCPortAttributeNameKey: @"Message"};
    else if ([key isEqualToString:@"outputMessageAddress"])
        return @{QCPortAttributeNameKey: @"Message Address"};
    else if ([key isEqualToString:@"outputMessageReceived"])
        return @{QCPortAttributeNameKey: @"Message Received"};
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
                if (!argument) {
                    if ([type isEqualToString:PEOSCMessageTypeTagTrue]) {
                        argument = @YES;
                    } else if ([type isEqualToString:PEOSCMessageTypeTagFalse]) {
                        argument = @NO;
                    } else if ([type isEqualToString:PEOSCMessageTypeTagImpulse]) {
                        // TODO - this should have special handling to actually pulse
                        argument = @YES;
                    } else if ([type isEqualToString:PEOSCMessageTypeTagNull]) {
                        // TODO - this should have special handling too
                        argument = [NSNull null];
                    }
                }

                if (!argument)
                    return;

                [structure addObject:@{[PEOSCMessage displayNameForType:type]: argument}];
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

    self.receiver = [[PEOSCReceiver alloc] initWithPort:self.port];
    self.receiver.delegate = self;

    NSError* error;
    BOOL status = [self.receiver beginListening:&error];
    if (!status) {
        CCErrorLog(@"ERROR - failed to build up receiver - %@", [error localizedDescription]);
    }
}

- (void)_tearDownReceiver {
    CCDebugLogSelector();
    if (self.receiver.isListening) {
        [self.receiver stopListeningWithCompletionHandler:^(BOOL success, NSError* error) {
            if (!success) {
                CCErrorLog(@"ERROR - failed to cleanly stop listening - %@", [error localizedDescription]);
            }
        }];
    }
    self.receiver = nil;
}

@end

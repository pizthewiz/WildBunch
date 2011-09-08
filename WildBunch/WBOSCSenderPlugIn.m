//
//  WBOSCSenderPlugIn.m
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 6 Sept 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import "WBOSCSenderPlugIn.h"
#import "WildBunch.h"
#import "WBOSCSenderViewController.h"

@interface WBMessageElement : NSObject <NSCoding>
+ (id)messageElementWithType:(NSString*)type portKey:(NSString*)portKey;
- (id)initWithType:(NSString*)type portKey:(NSString*)portKey;
@property (nonatomic, strong) NSString* type;
@property (nonatomic, strong) NSString* portKey;
@end

@implementation WBMessageElement
@synthesize type, portKey;
+ (id)messageElementWithType:(NSString *)type portKey:(NSString*)portKey {
    id messageDataSet = [[self alloc] initWithType:type portKey:portKey];
    return messageDataSet;
}
- (id)initWithType:(NSString*)typ portKey:(NSString*)por {
    self = [super init];
    if (self) {
        self.type = typ;
        self.portKey = por;
    }
    return self;
}
- (id)initWithCoder:(NSCoder*)decoder {
    self = [super init];
    if (self) {
        self.type = [decoder decodeObjectForKey:@"type"];
        self.portKey = [decoder decodeObjectForKey:@"portKey"];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder*)encoder {
    [encoder encodeObject:self.type forKey:@"type"];
    [encoder encodeObject:self.portKey forKey:@"portKey"];
}
@end

#pragma mark -

/*
static NSString* messageTypeForCode(NSString* code) {
    NSString* type = nil;
    if ([code isEqualToString:@"i"]) {
        type = PEOSCMessageTypeTagInteger;
    } else if ([code isEqualToString:@"f"]) {
        type = PEOSCMessageTypeTagFloat;
    } else if ([code isEqualToString:@"s"]) {
        type = PEOSCMessageTypeTagString;
    } else if ([code isEqualToString:@"b"]) {
        type = PEOSCMessageTypeTagBlob;
    } else if ([code isEqualToString:@"T"]) {
        type = PEOSCMessageTypeTagTrue;
    } else if ([code isEqualToString:@"F"]) {
        type = PEOSCMessageTypeTagFalse;
    } else if ([code isEqualToString:@"N"]) {
        type = PEOSCMessageTypeTagNull;
    } else if ([code isEqualToString:@"I"]) {
        type = PEOSCMessageTypeTagImpulse;
    }
    return type;
}

static BOOL shouldAddPortForType(NSString* type) {
    BOOL status = NO;
    if ([type isEqualToString:PEOSCMessageTypeTagInteger] || [type isEqualToString:PEOSCMessageTypeTagFloat] || [type isEqualToString:PEOSCMessageTypeTagString] || [type isEqualToString:PEOSCMessageTypeTagBlob])
        status = YES;
    return status;
}
*/

static NSString* const WBSenderExampleCompositionName = @"";

@interface WBOSCSenderPlugIn()
@property (nonatomic, strong) NSString* host;
@property (nonatomic) NSUInteger port;
@property (nonatomic, strong) NSMutableArray* messageElements;
@property (nonatomic, strong) PEOSCSender* sender;
- (void)_buildUpSender;
- (void)_tearDownSender;
- (void)_addMessageElement:(WBMessageElement*)element;
- (void)_removeMessageElement:(WBMessageElement*)element;
- (void)_addPortForMessageElement:(WBMessageElement*)element;
- (NSArray*)_types;
- (NSArray*)_arguments;
@end

@implementation WBOSCSenderPlugIn

@dynamic inputHost, inputPort, inputSendSignal, inputAddress;
@synthesize host, port, messageElements, sender;

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
	return kQCPlugInTimeModeNone;
}

+ (NSArray*)plugInKeys {
    return [NSArray arrayWithObjects:@"messageElements", nil];
}

#pragma mark -

- (QCPlugInViewController*)createViewController {
	return [[WBOSCSenderViewController alloc] initWithPlugIn:self viewNibName:@"Settings"];
}

#pragma mark -

- (id)init {
    self = [super init];
    if (self) {
        self.messageElements = [NSMutableArray array];
    }
    return self;
}

#pragma mark -

- (void)setSerializedValue:(id)serializedValue forKey:(NSString*)key {
    [super setSerializedValue:serializedValue forKey:key];

    // setup ports
    if ([key isEqualToString:@"messageElements"]) {
        for (WBMessageElement* element in self.messageElements) {
            [self _addPortForMessageElement:element];
        }
    }
}

#pragma mark - EXECUTION

- (BOOL)startExecution:(id <QCPlugInContext>)context {
	return YES;
}

- (void)enableExecution:(id <QCPlugInContext>)context {
    if (self.host && ![self.host isEqualToString:@""] && self.port)
        [self _buildUpSender];
}

- (BOOL)execute:(id <QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments {
    // negotiate new connection
    if ([self didValueForInputKeyChange:@"inputHost"] || [self didValueForInputKeyChange:@"inputPort"]) {
        CCDebugLog(@"host or port changed, will negotiate new connection");

        // store for safe keeping, may be needed stop/start
        self.host = self.inputHost;
        self.port = self.inputPort;

        [self _buildUpSender];
    }

    if ([self didValueForInputKeyChange:@"inputSendSignal"] && self.inputSendSignal) {
        NSArray* types = [self _types];
        if (!types.count) {
            CCErrorLog(@"ERROR - cannot send type-less message, consider using an Impulse instead");
            return YES;
        }
        PEOSCMessage* message = [[PEOSCMessage alloc] initWithAddress:self.inputAddress typeTags:types arguments:[self _arguments]];
        CCDebugLog(@"will send: %@", message);
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

//- (void)_setupInputsForTypeString:(NSString*)typesString {
//    for (NSUInteger idx = 0; idx < typesString.length; idx++) {
//        NSString* typeCode = [typesString substringWithRange:NSMakeRange(idx, 1)];
//        NSString* type = messageTypeForCode(typeCode);
//
//        BOOL shouldAddPort = shouldAddPortForType(type);
//        NSString* portKey = shouldAddPort ? [NSString stringWithFormat:@"argument-%d.%d", (long)[[NSDate date] timeIntervalSince1970], idx] : nil;
//
//        WBMessageElement* element = [WBMessageElement messageElementWithType:type portKey:portKey];
//        [self.messageElements addObject:element];
//    }
//}

- (void)_addMessageElement:(WBMessageElement*)element {
    [self _addPortForMessageElement:element];

    [self willChangeValueForKey:@"messageElements"];
    [self.messageElements addObject:element];
    [self didChangeValueForKey:@"messageElements"];
}

- (void)_removeMessageElement:(WBMessageElement*)element {
    if (element.portKey) {
        [self removeInputPortForKey:element.portKey];
    }

    [self willChangeValueForKey:@"messageElements"];
    [self.messageElements removeObject:element];
    [self didChangeValueForKey:@"messageElements"];
}

- (void)_addPortForMessageElement:(WBMessageElement*)element {
    if (element.portKey) {
        if ([element.type isEqualToString:PEOSCMessageTypeTagInteger]) {
            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"OSC Integer", QCPortAttributeNameKey, [NSNumber numberWithInt:INT_MIN], QCPortAttributeMinimumValueKey, [NSNumber numberWithInt:INT_MAX], QCPortAttributeMaximumValueKey, [NSNumber numberWithInt:0], QCPortAttributeDefaultValueKey, nil];
            [self addInputPortWithType:QCPortTypeNumber forKey:element.portKey withAttributes:attributes];
        } else if ([element.type isEqualToString:PEOSCMessageTypeTagFloat]) {
            // NB - setting min and max seemes to mess up the 0.0 value to 1.175e-38
//            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"OSC Float", QCPortAttributeNameKey, [NSNumber numberWithFloat:FLT_MIN], QCPortAttributeMinimumValueKey, [NSNumber numberWithFloat:FLT_MAX], QCPortAttributeMaximumValueKey, [NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey, nil];
            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"OSC Float", QCPortAttributeNameKey, [NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey, nil];
            [self addInputPortWithType:QCPortTypeNumber forKey:element.portKey withAttributes:attributes];
        } else if ([element.type isEqualToString:PEOSCMessageTypeTagString]) {
            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"OSC String", QCPortAttributeNameKey, @"Log Lady", QCPortAttributeDefaultValueKey, nil];
            [self addInputPortWithType:QCPortTypeString forKey:element.portKey withAttributes:attributes];
        }
    }
}

- (NSArray*)_types {
    NSMutableArray* types = [NSMutableArray array];
    for (WBMessageElement* element in self.messageElements) {
        [types addObject:element.type];
    }
    return (NSArray*)types;
}

- (NSArray*)_arguments {
    NSMutableArray* args = [[NSMutableArray alloc] init];
    for (WBMessageElement* element in self.messageElements) {
        if (!element.portKey)
            continue;
        id value = [self valueForInputKey:element.portKey];
        [args addObject:value];
    }
    return (NSArray*)args;
}

@end

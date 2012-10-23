//
//  WBOSCSenderViewController.m
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 8 Sept 2011.
//  Copyright (c) 2011-2012 Chorded Constructions. All rights reserved.
//

#import "WBOSCSenderViewController.h"
#import "WildBunch.h"

@implementation WBOSCMessageTypeTagTransformer
+ (Class)transformedValueClass {
    return [NSString class];
}
+ (BOOL)allowsReverseTransformation {
    return NO;
}
- (id)transformedValue:(id)value {
    return [PEOSCMessage displayNameForType:value];
}
@end

NSString* const WBOSCMessageParameterTypeKey = @"WBOSCMessageParameterTypeKey";
NSString* const WBOSCMessageParameterPortKey = @"WBOSCMessageParameterPortKey";
// synthesize a Boolean type over True and False
NSString* const WBOSCMessageTypeTagBoolean = @"WBOSCMessageTypeTagBoolean";
NSString* const WBOSCMessageTypeTagBooleanTitle = @"Boolean";


static BOOL shouldAddPortForType(NSString* type) {
    BOOL status = NO;
    if ([type isEqualToString:PEOSCMessageTypeTagInteger] || [type isEqualToString:PEOSCMessageTypeTagFloat] || [type isEqualToString:PEOSCMessageTypeTagString] || [type isEqualToString:WBOSCMessageTypeTagBoolean] || [type isEqualToString:PEOSCMessageTypeTagBlob])
        status = YES;
    return status;
}

@interface WBOSCSenderViewController()
@property (nonatomic, strong) NSArray* types;
@end

@implementation WBOSCSenderViewController

@synthesize parameters, typeTagPopUpBotton, types;

- (void)awakeFromNib {
    self.types = [NSArray arrayWithObjects:PEOSCMessageTypeTagInteger, PEOSCMessageTypeTagFloat, PEOSCMessageTypeTagString, WBOSCMessageTypeTagBoolean, PEOSCMessageTypeTagNull, PEOSCMessageTypeTagImpulse, nil];

    WBOSCMessageTypeTagTransformer* transformer = [[WBOSCMessageTypeTagTransformer alloc] init];
    __block NSMutableArray* titles = [NSMutableArray array];
    [self.types enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (obj == WBOSCMessageTypeTagBoolean) {
            [titles addObject:WBOSCMessageTypeTagBooleanTitle];
        } else {
            [titles addObject:[transformer transformedValue:obj]];
        }
    }];

    [self.typeTagPopUpBotton removeAllItems];
    [self.typeTagPopUpBotton addItemsWithTitles:titles];
}

#pragma mark -

- (IBAction)addMessageParameter:(id)sender {
    CCDebugLogSelector();

    NSString* type = [self.types objectAtIndex:self.typeTagPopUpBotton.indexOfSelectedItem];
    BOOL shouldAddPort = shouldAddPortForType(type);
    // AVOID - rdar://problem/10100572 QCPlugIn - inspector fails to display dynamic port values with dot in key name
    NSString* portKey = shouldAddPort ? [NSString stringWithFormat:@"arg%ld-%ld", (long)[[NSDate date] timeIntervalSince1970], [(NSArray*)self.parameters.content count]] : nil;

    NSDictionary* param = [NSDictionary dictionaryWithObjectsAndKeys:type, WBOSCMessageParameterTypeKey, portKey, WBOSCMessageParameterPortKey, nil];
    [self.plugIn performSelector:@selector(_addMessageParameter:) withObject:param];
}

- (IBAction)removeMessageParameter:(id)sender {
    CCDebugLogSelector();

    NSUInteger selectionIndex = [self.parameters selectionIndex];
    if (selectionIndex == NSNotFound)
        return;

    id param = [(NSArray*)self.parameters.content objectAtIndex:selectionIndex];
    [self.plugIn performSelector:@selector(_removeMessageParameter:) withObject:param];
}

@end

//
//  WBOSCSenderViewController.h
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 8 Sept 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <AppKit/AppKit.h>

extern NSString* const WBOSCMessageParameterTypeKey;
extern NSString* const WBOSCMessageParameterPortKey;
extern NSString* const WBOSCMessageTypeTagBoolean;

@interface WBOSCMessageTypeTagTransformer : NSValueTransformer
@end

@interface WBOSCSenderViewController : QCPlugInViewController
@property (nonatomic, assign) IBOutlet NSArrayController* parameters;
@property (nonatomic, assign) IBOutlet NSPopUpButton* typeTagPopUpBotton;
- (IBAction)addMessageParameter:(id)sender;
- (IBAction)removeMessageParameter:(id)sender;
@end

//
//  WBOSCSenderViewController.h
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 8 Sept 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <AppKit/AppKit.h>

@interface WBOSCSenderViewController : QCPlugInViewController
@property (nonatomic, assign) IBOutlet NSArrayController* elements;
@property (nonatomic, assign) IBOutlet NSPopUpButton* typeTagPopUpBotton;

- (IBAction)addMessageElement:(id)sender;
- (IBAction)removeMessageElement:(id)sender;
@end

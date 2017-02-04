//
//  ViewController.h
//  RFIDTagReader
//
//  Created by vingleo on 16/7/15.
//  Copyright © 2016年 Vingleo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController<NSComboBoxDataSource,NSComboBoxDelegate>


@property (weak) IBOutlet NSTextField *messageLabel;
@property (weak) IBOutlet NSTextField *orgTextField;
@property (weak) IBOutlet NSTextField *shortTextField;
@property (weak) IBOutlet NSTextField *cardTagTextField;
@property (weak) IBOutlet NSTextField *puTextField;
@property (weak) IBOutlet NSComboBox *selectAlgo;

@property (weak) IBOutlet NSButton *cardType;


@property (weak) IBOutlet NSButton *testButton;
@property (weak) IBOutlet NSButton *getTagButton;


- (IBAction)getTag:(id)sender;
- (IBAction)connect:(id)sender;
- (IBAction)changeCardType:(NSButton *)sender;
- (IBAction)choosealgo:(id)sender;


@end


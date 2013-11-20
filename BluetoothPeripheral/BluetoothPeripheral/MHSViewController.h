//
//  MHSViewController.h
//  BluetoothPeripheral
//
//  Created by Zach Dennis on 11/5/13.
//  Copyright (c) 2013 Zach Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface MHSViewController : UIViewController <CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
- (IBAction)updateValue:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@end

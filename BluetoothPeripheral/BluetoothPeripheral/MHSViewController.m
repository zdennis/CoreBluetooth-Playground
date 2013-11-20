//
//  MHSViewController.m
//  BluetoothPeripheral
//
//  Created by Zach Dennis on 11/5/13.
//  Copyright (c) 2013 Zach Dennis. All rights reserved.
//

#import "MHSViewController.h"

@interface MHSViewController ()
  @property CBMutableCharacteristic *customCharacteristic;
  @property CBMutableService *customService;
  @property NSInteger value;
@end

static NSString * const kServiceUUID = @"C60BC519-BF72-433F-9D35-F590875CE161";
static NSString * const kCharacteristicUUID = @"0FA586DA-F9BF-4F80-8DB2-AF134BB10B52";

@implementation MHSViewController


- (void)viewDidLoad
{
  [super viewDidLoad];

	// Do any additional setup after loading the view, typically from a nib.
  self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];

  [self updateValue: self];
}

# pragma mark PeripheralManagerDelegate

- (void) peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
  if(error){
    NSLog(@"Oh wait, I failed: %@", error);
  } else {
    NSLog(@"Adding a service: %@", kServiceUUID);
    // start advertising the service
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey : @"MHSPlayground",
                                               CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:kServiceUUID]] }];
  }
}

- (void) peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
  switch(peripheral.state){
    case CBPeripheralManagerStatePoweredOn:
      [self setupService];
      break;
    default:
      NSLog(@"Peripheral Manager did change state");
      break;
  }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
  NSLog(@"Started to advertise");
  if(error){
    NSLog(@"Error advertising: %@", error);
  }
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
  NSLog(@"Central subscribed");
  [self broadcastValue];
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
  NSLog(@"Received read request");
//  [self.peripheralManager respondToRequest:request withResult:<#(CBATTError)#>
}

- (void) setupService {
  // Create the characteristic UUID
  CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
  
  // create the characteristic
  self.customCharacteristic = [[CBMutableCharacteristic alloc] initWithType: characteristicUUID properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
  
  // create the service uuid
  CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
  self.customService = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
  
  [self.customService setCharacteristics:@[self.customCharacteristic]];
  
  // publish
  [self.peripheralManager addService:self.customService];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated {
  NSLog(@"View will disappear");
}

- (IBAction)updateValue:(id)sender {
  self.value = [self generateValue];
  self.valueLabel.text = [NSString stringWithFormat:@"%ld", (long)self.value];
  [self broadcastValue];
}

- (NSInteger) generateValue {
  NSInteger value = arc4random() % 100;
  return value;
}

- (void) broadcastValue {
  if(self.customCharacteristic){
    NSString *str = [NSString stringWithFormat:@"%ld", (long) self.value];
    NSData *updatedValue = [str dataUsingEncoding:NSUTF8StringEncoding]; // fetch the characteristic's new value
    BOOL didSendValue = [self.peripheralManager updateValue:updatedValue
                                          forCharacteristic: self.customCharacteristic onSubscribedCentrals:nil];
    NSLog(@"Did send updated value: %@", updatedValue);
  }
}


@end

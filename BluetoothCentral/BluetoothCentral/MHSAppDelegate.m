//
//  MHSAppDelegate.m
//  BluetoothCentral
//
//  Created by Zach Dennis on 11/5/13.
//  Copyright (c) 2013 Zach Dennis. All rights reserved.
//

#import "MHSAppDelegate.h"

@interface MHSAppDelegate ()
  @property NSTimer *scanTimer;
@end

static NSString * const kServiceUUID = @"C60BC519-BF72-433F-9D35-F590875CE161";
static NSString * const kCharacteristicUUID = @"0FA586DA-F9BF-4F80-8DB2-AF134BB10B52";

@implementation MHSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)startScan:(NSTimer *)timer {
  NSLog(@"Start scanning");
  // Scans for any peripheral with the given service UUID
	[self.centralManager scanForPeripheralsWithServices:@[ [CBUUID UUIDWithString:kServiceUUID] ] options: @{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];

  // Scans for any peripheral
  //      [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
	
  self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(pauseScan:) userInfo:nil repeats:NO];
}

- (void)pauseScan:(NSTimer *)timer {
  NSLog(@"Pause scanning");
	[self.centralManager stopScan];
	self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(startScan:) userInfo:nil repeats:NO];
}


# pragma mark CBCentralManagerDelegate

- (void) centralManagerDidUpdateState:(CBCentralManager *)central {
  NSLog(@"centralManagerDidUpdateState");
  switch (central.state) {
    case CBCentralManagerStatePoweredOn:
      self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(startScan:) userInfo:nil repeats:NO];
      // Scans for any peripheral with the given service UUID
//
//      [self.centralManager scanForPeripheralsWithServices:@[ [CBUUID UUIDWithString:kServiceUUID] ] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
      
      // Scans for any peripheral
//      [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];

      break;
    default:
      NSLog(@"centralManagerDidUpdateState NOPE");
      break;
  }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
  NSLog(@"didDiscoverPeripheral");
  
  //  Stops scanning for peripheral
  [self.centralManager stopScan];
  
  if (self.peripheral != peripheral) {
    self.peripheral = peripheral;
    NSLog(@"Connecting to peripheral at signal strength %@", RSSI);

    // Connects to the discovered peripheral
    [self.centralManager connectPeripheral:peripheral options:nil];
  }
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  NSLog(@"Connected to %@", peripheral);
  
  // clear data that we already have
  [self.data setLength: 0];
  
  // set the peripheral delegate
  peripheral.delegate = self;
  
  // ask the peripheral to discover services
  [peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUID]]];
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  NSLog(@"Failed to connect to %@", peripheral);
}

-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  NSLog(@"Trying to disconnected");
}


# pragma mark CBPeripheralDelegate

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
  if(error){
    NSLog(@"Failed discovering services for peripheral: %@", error);
  } else {
    for(CBService *service in peripheral.services){
      // Discovers the characteristics for a given service
      NSLog(@"Discovered service: %@", service.UUID);
      if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
        [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kCharacteristicUUID]] forService:service];
      }
      
    }
  }
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
  if(error){
    NSLog(@"Failed discovering characteristics for peripheral");
  } else {
    for(CBCharacteristic *characteristic in service.characteristics){
      NSLog(@"Discover characteristic %@", characteristic.UUID);
      [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
  }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  if(error){
    NSLog(@"Failed updating characteristic notification for peripheral: %@", error);
  } else {
    if (characteristic.isNotifying) {
      NSLog(@"Notification began on %@", characteristic);
      [peripheral readValueForCharacteristic:characteristic];
    } else {
      // so disconnect from the peripheral
      NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
      [peripheral setNotifyValue:NO forCharacteristic:characteristic];
      [self.centralManager cancelPeripheralConnection:self.peripheral];
    }
  }
}
- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  if(error){
    NSLog(@"Failed reading characteristic value for peripheral: %@", error);
  } else {
    NSString *str = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"value  %@", str);
    [self.centralManager cancelPeripheralConnection:peripheral];
    self.peripheral = nil;
  }
}

- (void) applicationWillTerminate:(NSNotification *)notification {
  if(self.peripheral){
    [self.centralManager cancelPeripheralConnection: self.peripheral];
    self.peripheral = nil;
  }
}

@end

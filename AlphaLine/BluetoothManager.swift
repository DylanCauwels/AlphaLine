//
//  BTManager.swift
//  AlphaLine
//
//  Created by Jarrad Cisco on 2/6/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - Core Bluetooth Service IDs
let BLE_UART_Service_CBUUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
 
// MARK: - Core Bluetooth Characteristic IDs
let BLE_Tx_Characteristic_CBUUID = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
let BLE_Rx_Characteristic_CBUUID = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")

// MARK: - UART Protocol Special Chars
let Rx_Start = Character("{")
let Rx_End = Character("}")

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // Core BT member vars
    var centralManager: CBCentralManager?
    var peripheralDevice: CBPeripheral?
    
    // Sensor Data vars
    var angles = Dictionary<String, Double>()
    var buffer: Data?
    
    var view: ViewController
    
    init(view: ViewController) {
        self.view = view
        super.init()
        // concurrent queue for background tasks
        let centralQueue = DispatchQueue(label: "com.example.centralQueueName", attributes: .concurrent)
        self.centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    init(view: ViewController, centralManager: CBCentralManager) {
        self.view = view
        self.centralManager = centralManager
        super.init()
    }
    
    // MARK: - CBCentralManagerDelegate methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
    
        case .unknown:
            print("Bluetooth status is UNKNOWN")
            
        case .resetting:
            print("Bluetooth status is RESETTING")
            
        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")
            
        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")
            
        case .poweredOff:
            print("Bluetooth status is POWERED OFF")
            
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
            
            DispatchQueue.main.async { () -> Void in
                // TODO start pairing animation
            }
            
            // scan for peripherals with our service
            centralManager?.scanForPeripherals(withServices: [BLE_UART_Service_CBUUID])
            
        }
    }
    
    // look at peripherals with our service
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print(peripheral.name!)
        decodePeripheralState(peripheralState: peripheral.state)
        // store peripheral
        peripheralDevice = peripheral
        // set peripheral's delegate as self
        peripheralDevice?.delegate = self
        
        // stop scanning to preserve battery life
        // TODO: update this for multiple devices
        centralManager?.stopScan()
        
        // connect to peripheral
        centralManager?.connect(peripheralDevice!)
    }
    
    // "Invoked when a connection is successfully created with a peripheral."
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
       
       DispatchQueue.main.async { () -> Void in
           // TODO: update UI
       }
       
       // look for our service(s) on peripheral
       peripheralDevice?.discoverServices([BLE_UART_Service_CBUUID])
    }
    
    // peripheral has disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("Device Disconnected.")
        
        DispatchQueue.main.async { () -> Void in
            // TODO: - update UI
        }
        
        // start scanning for a new device
        centralManager?.scanForPeripherals(withServices: [BLE_UART_Service_CBUUID])
    }
    
    // MARK: - CBPeripheralDelegate methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        decodePeripheralState(peripheralState: peripheral.state)
        for service in peripheral.services! {
            if service.uuid == BLE_UART_Service_CBUUID {
                print("Service: \(service)")
                // look for the characterics we want
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    // confirm we have the characteristics and services we want
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
       for characteristic in service.characteristics! {
           print(characteristic)
           if characteristic.uuid == BLE_Rx_Characteristic_CBUUID {
               // subscribe to regular notifications on Rx line
               peripheral.setNotifyValue(true, for: characteristic)
           }
       }
    }
    
    // read updated values
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
           if characteristic.uuid == BLE_Rx_Characteristic_CBUUID {
                if cacheData(data: characteristic.value) {
                    decodeRx()
                }
            
               DispatchQueue.main.async { () -> Void in
                   // TODO: -update UI
               }
           }
       }
    
    // MARK: - UTIL funcs
    
    func decodePeripheralState(peripheralState: CBPeripheralState) {
        switch peripheralState {
        case .disconnected:
            print("Peripheral state: disconnected")
        case .connected:
            print("Peripheral state: connected")
        case .connecting:
            print("Peripheral state: connecting")
        case .disconnecting:
            print("Peripheral state: disconnecting")
        }
    }
    
    func cacheData(data: Data?) -> Bool {
        if let data = data {
            if data[data.startIndex] == Rx_Start.asciiValue {
                buffer = data
            }
            else {
                buffer?.append(data)
            }
            if data[data.endIndex - 1] == Rx_End.asciiValue {
                return true
            }
        }
        return false
    }
    
    func decodeRx() {
        if let buffer = buffer {
            var data: String! = String(data: buffer, encoding: .utf8)
            // trim leading and trailing brackets
            data.removeFirst()
            data.removeLast()
            
            let angleArr = data.components(separatedBy: ",")
            
            var printArr: Array<Double> = Array<Double>()
            
            for i in 0..<angleArr.endIndex {
                if let angle = Double(angleArr[i]) {
                    print("\(Locations[i]): \(angle) degrees")
                    angles[Locations[i]] = angle
                    printArr.append(angle)
                }
            }
            DispatchQueue.main.async { () -> Void in
                self.view.writeData(printArr)
            }
        }
    }
    
}

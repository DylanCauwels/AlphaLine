//
//  ViewController.swift
//  AlphaLine
//
//  Created by Dylan Cauwels on 2/5/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import UIKit
import CoreBluetooth

// MARK: - Core Bluetooth Service IDs
let BLE_UART_Service_CBUUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
 
// MARK: - Core Bluetooth Characteristic IDs
let BLE_Tx_Characteristic_CBUUID = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
let BLE_Rx_Characteristic_CBUUID = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")

let Rx_Start = Character("{")
let Rx_End = Character("}")

// order of sensor locations as sent by peripheral
let Locations = ["A1", "A2", "A3", "A4", "Left", "Right"]

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Core BT member vars
    var centralManager: CBCentralManager?
    var peripheralDevice: CBPeripheral?
    
    var angles = Dictionary<String, Float>()
    var buffer: Data?
    
    @IBAction func buttonPressed(_ sender: Any) {
        writeData(data: [Double(arc4random()),Double(arc4random()), Double(arc4random()), Double(arc4random()), Double(arc4random()), Double(arc4random())])
    }
    
    @IBOutlet weak var DataLabel: UILabel!
    
    @IBOutlet weak var textbox: UITextView!
        
    func convertArrtoString(array: Array<Double>) -> String {
        var returnable = "["
        for value in array {
            returnable = returnable + String(value) + ","
        }
        return returnable + "]"
    }
    
    // writes data to the textbox with datetime
    func writeData(data:Array<Double>) {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        // compiling message
        let datetime: String = String(hour) + ":" + String(minutes) + ":" + String(seconds)
        let received: String = "\nData: " + convertArrtoString(array: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]) + " \n\tReceived At: " + datetime
        let text: String = textbox.text
        textbox.text =  received + text
    }
    
    // writes message to the textbox
    func writeMessage(message: String) {
        textbox.text = message + textbox.text
    }
    
    override func viewDidLoad() {
        // gives access to main view property before its on screen
        super.viewDidLoad()
        /// UI Commands
        DataLabel.font = DataLabel.font.withSize(20)
        
        /// BLE Commands
        // concurrent queue for background tasks
        let centralQueue = DispatchQueue(label: "com.example.centralQueueName", attributes: .concurrent)
        // delegate central manager
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
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
               cacheData(data: characteristic.value)
            
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
    
    func cacheData(data: Data?) {
        if data![data!.startIndex] == Rx_Start.asciiValue {
            buffer = data
        }
        else {
            buffer?.append(data!)
        }
        if data![data!.endIndex - 1] == Rx_End.asciiValue {
            decodeRx()
        }
    }
    
    func decodeRx() {
        if let buffer = buffer {
            var data: String! = String(data: buffer, encoding: .utf8)
            // trim leading and trailing brackets
            data.removeFirst()
            data.removeLast()
            
            let angleArr = data.components(separatedBy: ",")
            
            for i in 0..<angleArr.endIndex {
                let angle = Float(angleArr[i])
                print("\(Locations[i]): \(angle!) degrees")
                angles[Locations[i]] = Float(angleArr[i])
            }
        }
    }
}

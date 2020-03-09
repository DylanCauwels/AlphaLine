//
//  BluetoothManager.swift
//  AlphaLine
//
//  Created by Jarrad Cisco on 2/6/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - Core Bluetooth Service IDs
private let BLE_UART_Service_CBUUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
 
// MARK: - Core Bluetooth Characteristic IDs
private let BLE_Tx_Characteristic_CBUUID = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
private let BLE_Rx_Characteristic_CBUUID = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")

// MARK: - UART Protocol Special Chars
private let Rx_Start = Character("{")
private let Rx_End = Character("\n")

// Expected Number of Values Transmitted by Device per Message
private let EXPECTED_VALUES_COUNT = 6
private let STATUS_FIELDS_COUNT = 1

// Pairing State
enum BluetoothPairingState {
    case searching, found, connecting, paired, transitioned, healthy, reconnecting, error;
}
// Device Battery State
enum DeviceBatteryState {
    case searching, high, low, dead;
}

// Observer Type Aliases
typealias StatusObserverBlock = (_ newStatus: BluetoothPairingState, _ oldStatus: BluetoothPairingState) -> ()
typealias StatusObserversEntry = (observer: AnyObject, block: StatusObserverBlock)
typealias AngleObserverBlock = (_ newValue: [Double], _ oldValue: [Double]) -> ()
typealias AngleObserversEntry = (observer: AnyObject, block: AngleObserverBlock)
typealias BatteryObserverBlock = (_ newState: DeviceBatteryState, _ oldState: DeviceBatteryState) -> ()
typealias BatteryObserversEntry = (observer: AnyObject, block: BatteryObserverBlock)

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // Core BT member vars
    private var centralManager: CBCentralManager?
    private var peripheralDevice: CBPeripheral?
    
    // Device Data
    private var buffer: Data?
    var deviceName: String?
    private var packetNo: Int?
    private var droppedPackets: Int = 0
    private var status: BluetoothPairingState {
        // notify observers when bluetooth status changes
        didSet {
            statusObservers.forEach({ (entry: StatusObserversEntry) in
                let (_, block) = entry
                DispatchQueue.main.async { () -> Void in
                    block(self.status, oldValue)
                }
            })
        }
    }
    private var angles: [Double] {
        // notify observers when receiving updated angles
        didSet {
            angleObservers.forEach({ (entry: AngleObserversEntry) in
                let (_, block) = entry
                DispatchQueue.main.async { () -> Void in
                    block(self.angles, oldValue)
                }
            })
        }
    }
    private var batteryLevel: DeviceBatteryState {
        // notify observers when device battery level changes
        didSet {
            // only notify if value is changed
            if batteryLevel != oldValue {
                batteryObservers.forEach({ (entry: BatteryObserversEntry) in
                    let (_, block) = entry
                    DispatchQueue.main.async { () -> Void in
                        block(self.batteryLevel, oldValue)
                    }
                })
            }
        }
    }
    
    
    
    // Observer Arrays
    // Note: Entries are not easily hashable, so we choose not to use a Set
    private var statusObservers: Array<StatusObserversEntry>
    private var angleObservers: Array<AngleObserversEntry>
    private var batteryObservers: Array<BatteryObserversEntry>
    
    override init() {
        self.statusObservers = []
        self.angleObservers = []
        self.batteryObservers = []
        self.angles = []
        self.status = .error
        self.batteryLevel = .searching
        super.init()
        // concurrent queue for background tasks
        let centralQueue = DispatchQueue(label: "com.example.centralQueueName", attributes: .concurrent)
        self.centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    internal init(centralManager: CBCentralManager) {
        self.centralManager = centralManager
        self.statusObservers = []
        self.angleObservers = []
        self.batteryObservers = []
        self.angles = []
        self.batteryLevel = .searching
        self.status = .error
        super.init()
    }
    
    // MARK: - Observer Subscription Methods
    
    /// Subscribe to notifications when Bluetooth pairing state is changed. Returns current state.
    /// - Parameters:
    ///   - observer: object to subscribe
    ///   - block: closure to call with updated status
    func subscribeToStatus(observer: AnyObject, block: @escaping StatusObserverBlock) -> BluetoothPairingState {
        let entry: StatusObserversEntry = (observer: observer, block: block)
        statusObservers.append(entry)
        return status
    }
    
    func unsubscribeFromStatus(observer: AnyObject) {
        let filtered = statusObservers.filter { entry in
            let (owner, _) = entry
            return owner !== observer
        }

        statusObservers = filtered
    }
    
    /// Subscribe to notifications when device measurement (in angles) is changed. Returns current values.
    /// - Parameters:
    ///   - observer: subscribing object
    ///   - block: closure to call with updated measurements
    func subscribeToAngles(observer: AnyObject, block: @escaping AngleObserverBlock) -> [Double] {
        let entry: AngleObserversEntry = (observer: observer, block: block)
        angleObservers.append(entry)
        return angles
    }
    
    func unsubscribeFromAngles(observer: AnyObject) {
        let filtered = angleObservers.filter { entry in
            let (owner, _) = entry
            return owner !== observer
        }

        angleObservers = filtered
    }
    
    /// Subscribe to notifications when device battery level changes. Returns current value.
    /// - Parameters:
    ///   - observer: subscribing object
    ///   - block: closure to call with updated value
    func subscribeToBatteryLevel(observer: AnyObject, block: @escaping BatteryObserverBlock) -> DeviceBatteryState {
        let entry = (observer: observer, block: block)
        batteryObservers.append(entry)
        return batteryLevel
    }
    
    func unsubscribeFromBatteryLevel(observer: AnyObject) {
        let filtered = batteryObservers.filter { entry in
            let (owner, _) = entry
            return owner !== observer
        }
        batteryObservers = filtered
    }
    
    // MARK: - CBCentralManagerDelegate methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
    
        case .unknown:
            print("Bluetooth status is UNKNOWN")
            status = .error
        case .resetting:
            print("Bluetooth status is RESETTING")
            status = .error
        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")
            status = .error
        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")
            status = .error
        case .poweredOff:
            print("Bluetooth status is POWERED OFF")
            status = .error
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
            
            DispatchQueue.main.async { () -> Void in
                // TODO start pairing animation
            }
            
            // scan for peripherals with our service
            central.scanForPeripherals(withServices: [BLE_UART_Service_CBUUID])
            status = .searching
        }
    }
    
    // look at peripherals with our service
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name {
            print("Discovered \(name)")
        }
        decodePeripheralState(peripheralState: peripheral.state)
        // store peripheral
        peripheralDevice = peripheral
        // set peripheral's delegate as self
        peripheralDevice?.delegate = self
        
        // stop scanning to preserve battery life
        // TODO: update this for multiple devices
        centralManager?.stopScan()
        
        status = .found
        
        // connect to peripheral
        centralManager?.connect(peripheralDevice!)
    }
    
    // "Invoked when a connection is successfully created with a peripheral."
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
       
        DispatchQueue.main.async { () -> Void in
           // TODO: update UI
        }
       
        status = .paired
        // look for our service(s) on peripheral
        peripheralDevice?.discoverServices([BLE_UART_Service_CBUUID])
    }
    
    // peripheral has disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("Device Disconnected.")
        
        DispatchQueue.main.async { () -> Void in
            // TODO: - update UI
        }
        
        status = .searching
        batteryLevel = .searching
        // start scanning for a new device
        centralManager?.scanForPeripherals(withServices: [BLE_UART_Service_CBUUID])
    }
    
    // MARK: - CBPeripheralDelegate methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        decodePeripheralState(peripheralState: peripheral.state)
        for service in peripheral.services! {
            if service.uuid == BLE_UART_Service_CBUUID {
                // look for the characterics we want
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    // confirm we have the characteristics and services we want
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            if characteristic.uuid == BLE_Rx_Characteristic_CBUUID {
                // subscribe to regular notifications on Rx line
                status = .transitioned
                batteryLevel = .high
                deviceName = peripheral.name
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    // read updated values
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
           if characteristic.uuid == BLE_Rx_Characteristic_CBUUID {
                // cache data, if complete packet, decode and notify
                if cacheData(data: characteristic.value) {
                    decodeRx()
                }
           }
       }
    
    // MARK: - UTIL funcs
    
    private func decodePeripheralState(peripheralState: CBPeripheralState) {
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
    
    private func cacheData(data: Data?) -> Bool {
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
    
    private func decodeRx() {
        if let buffer = buffer {
            var data: String! = String(data: buffer, encoding: .utf8)
            print("Data received: \(data!)")
            // trim leading and trailing brackets and newline
            data.removeFirst()
            data.removeLast()
            data.removeLast()
            
            let values = data.components(separatedBy: ",")
            
            if values.count != EXPECTED_VALUES_COUNT + STATUS_FIELDS_COUNT {
                print("WARNING: Expected \(EXPECTED_VALUES_COUNT + STATUS_FIELDS_COUNT) values but got \(values.count)")
            }
            
            var angles: [Double] = []
                
            // Parse Angle Values
            for i in 0..<EXPECTED_VALUES_COUNT {
                if let angle = Double(values[i]) {
                    angles.append(angle)
                }
                else {
                    print("Could not convert \(values[i]) to Double")
                }
            }
            
            if angles.count == EXPECTED_VALUES_COUNT {
                self.angles = angles
                // Parse Packet No, count dropped packets
                if let newNo = Int(values[EXPECTED_VALUES_COUNT + STATUS_FIELDS_COUNT - 1]) {
                    if let prevNo = self.packetNo {
                        droppedPackets += (newNo - prevNo - 1)
                    }
                    self.packetNo = newNo
                }
            }
            else {
                print("Not all values could be converted to Float, ignoring message")
            }
            
            
        }
    }
    
}

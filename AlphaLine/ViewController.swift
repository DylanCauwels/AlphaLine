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

// MARK: - Main Storyboard
class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    let imageConfiguration = UIImage.SymbolConfiguration(scale: .medium)
    
    func stopTimer(timer: Timer) {
        if timer.isValid {
            timer.invalidate()
        }
    }
    
    func getSymbol(color: UIColor, symbol: String) -> UIImage {
        return (UIImage(systemName: symbol, withConfiguration: imageConfiguration)?.withTintColor(color, renderingMode: .alwaysOriginal))!
    }
    
    func formatView(view: UIView) {
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
        view.layer.cornerRadius = 10
    }
    
    @objc func blink(timer: Timer) {
        let symbol: UIImageView = timer.userInfo as! UIImageView
        if symbol.alpha == 1.0 {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                symbol.alpha = 0.0
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                symbol.alpha = 1.0
            }, completion: nil)
        }
    }
    // MARK: Bluetooth Subview
    @IBOutlet weak var BTView: UIView!
    @IBOutlet weak var BTSubview: UIView!
    @IBOutlet weak var BTSymbol: UIImageView!
    @IBOutlet weak var loadingMessage: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    var iconTimer: Timer?
    
    func formatBT() {
        formatView(view: BTView)
        formatBTImage(color: .gray)
        progressBar.progress = 0.0
    }
    
    
    func formatBTView() {
        // BT view border
        self.BTView.layer.borderWidth = 2
        self.BTView.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
        self.BTView.layer.cornerRadius = 10
        // Progress bar init
        progressBar.setProgress(0.0, animated: false)
    }
    
    func formatBTImage(color: UIColor) {
        BTSymbol.image = getSymbol(color: color, symbol: "dot.radiowaves.left.and.right")
        BTSymbol.alpha = 1.0
    }
    
    var BTState: PairingState?
    enum PairingState {
        case searching, found, connecting, paired, transitioned, healthy, reconnecting, error;
    }
    var deviceName: String?
    
    // TODO: refactor method to produce symbol with diff colors
    func changeBTState() {
        if let state: PairingState = BTState {
            switch state {
                case .searching:
                    // TODO: be able to re-add progress bar
                    iconTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(blink), userInfo: self.BTSymbol, repeats: true)
                    progressBar.setProgress(0.1, animated: true)
                    loadingMessage.text = "Searching..."
                case .found:
                    progressBar.setProgress(0.3, animated: true)
                    loadingMessage.text = "Device Found"
                case .connecting:
                    progressBar.setProgress(0.6, animated: true)
                    loadingMessage.text = "Connecting..."
                case .paired:
                    progressBar.setProgress(1.0, animated: true)
                    loadingMessage.text = "Paired"
                    // stop timer and fade out old image for replacement
                    iconTimer?.invalidate()
                    if BTSymbol.alpha == 1.0 {
                        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                            self.BTSymbol.alpha = 0.0
                        }, completion: {(finished:Bool) in
                            self.formatBTImage(color: .systemBlue)
                            UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                              self.BTSymbol.alpha = 1.0
                            }, completion: nil)
                        })
                    }
                case .transitioned:
                    progressBar.removeFromSuperview()
                    if let device = deviceName {
                        loadingMessage.text = device
                    } else {
                        loadingMessage.text = "AlphaLine Prototype v1.12"
                    }
                    //TODO: have the Subview resize instead of just centering the content within the adjusted content subview
                    BTSubview.center = CGPoint(x: BTView.frame.size.width  / 2, y: BTView.frame.size.height / 2)
                    BTState = .healthy
            case .healthy:
                stopTimer(timer: iconTimer!)
                formatBTImage(color: .systemBlue)
            case .reconnecting:
                formatBTImage(color: .systemYellow)
                iconTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(blink), userInfo: self.BTSymbol, repeats: true)
            case .error:
                stopTimer(timer: iconTimer!)
                formatBTImage(color: .systemGray)
            }
        }
    }
    
    
    // MARK: Battery Subview
    @IBOutlet weak var batteryView: UIView!
    @IBOutlet weak var batteryImage: UIImageView!
    
    var batteryTimer: Timer?
    
    // TODO: refactor into single border change method
    func formatBattery() {
        formatBatteryView()
        formatBatteryImage(color: .systemGray, symbol: "battery.100")
    }
    
    func formatBatteryView() {
        self.batteryView.layer.borderWidth = 2
        self.batteryView.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
        self.batteryView.layer.cornerRadius = 10
    }
    
    func formatBatteryImage(color: UIColor, symbol: String) {
        batteryImage.image = getSymbol(color: color, symbol: symbol)
        batteryImage.alpha = 1.0
    }
    
    enum BatteryState {
        case searching, high, low, dead;
    }
    var batteryState: BatteryState?
    func changeBatteryState () {
        if let state = batteryState {
            switch state {
            case .searching:
                formatBatteryImage(color: .systemGray, symbol: "battery.100")
                batteryTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(blink), userInfo: self.batteryImage, repeats: true)
            case .high:
                stopTimer(timer: batteryTimer!)
                formatBatteryImage(color: .green, symbol: "battery.100")
            case .low:
                formatBatteryImage(color: .orange, symbol: "battery.25")
                batteryTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(blink), userInfo: self.batteryImage, repeats: true)
            case .dead:
                stopTimer(timer: batteryTimer!)
                formatBatteryImage(color: .red, symbol: "battery.0")
            }
        } else {
            print("battery state uninitialized")
        }
    }
    
    // MARK: Testing Subview
    @IBOutlet weak var testView: UIView!
    
    @IBAction func testBT(_ sender: Any) {
        if let state = BTState {
            switch state {
            case .searching:
                BTState = .found
            case .found:
                BTState = .connecting
            case .connecting:
                BTState = .paired
            case .paired:
                BTState = .transitioned
            case .transitioned:
                BTState = .healthy
            case .healthy:
                BTState = .reconnecting
            case .reconnecting:
                BTState = .error
            case .error:
                BTState = .healthy
            }
        } else {
            BTState = .searching
        }
        changeBTState()
    }
    
    @IBAction func testBattery(_ sender: Any) {
        if let state = batteryState {
            switch state {
            case .searching:
                batteryState = .high
            case .high:
                batteryState = .low
            case .low:
                batteryState = .dead
            case .dead:
                batteryState = .searching
            }
        } else {
            batteryState = .searching
        }
        changeBatteryState()
    }
    
    @IBAction func testData(_ sender: Any) {
        writeData(data: arc4random())
    }
    
    func formatTesting() {
        self.testView.layer.borderWidth = 2
        self.testView.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
        self.testView.layer.cornerRadius = 10
    }
    
    // MARK: Network Display Subview
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var dataBox: UITextView!
    @IBOutlet weak var dataView: UIView!

    func formatNetwork() {
        dataLabel.font = dataLabel.font.withSize(20)
        self.dataView.layer.borderWidth = 2
        self.dataView.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
        self.dataView.layer.cornerRadius = 10
        
        self.dataBox.layer.cornerRadius = 5
    }
    // writes data to the textbox with datetime
    func writeData(data:UInt32) {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        // compiling message
        let datetime: String = String(hour) + ":" + String(minutes) + ":" + String(seconds)
        let received: String = "\nData: " + String(data) + " \n\tReceived At: " + datetime
        writeMessage(message: received)
    }
    
    // writes message to the dataBox
    func writeMessage(message: String) {
        dataBox.text = message + dataBox.text
    }
    
    
    // MARK: - Core BT member vars
    var centralManager: CBCentralManager?
    var peripheralDevice: CBPeripheral?
    
    // MARK: - Main
    override func viewDidLoad() {
        // gives access to main view property before its on screen
        super.viewDidLoad()
        // UI Commands
        formatBT()
        formatBattery()
        formatTesting()
        formatNetwork()
        
        // BLE Commands
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
               
           // TODO: decode transmitted data
                print(characteristic.value)
            
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
    
    // TODO: -change this
    func decodeRx(msg: String) {
        print(msg);
    }
}

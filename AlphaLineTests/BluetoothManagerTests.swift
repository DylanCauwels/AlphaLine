//
//  BTManagerTests.swift
//  AlphaLineTests
//
//  Created by Jarrad Cisco on 2/6/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import XCTest
import CoreBluetooth
import AlphaLine

class BluetoothManagerTests: XCTestCase {
    
    var manager: BluetoothManager!
    var view: ViewController!
    var central: MockCBCentralManager!
    var peripheral: CBPeripheral!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        view = MockViewController(coder: NSCoder())
        central = MockCBCentralManager()
        
        self.manager = BluetoothManager(view: view!, centralManager: central!)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func centralManagerDidUpdateState() {
        // TODO: - check that UI was updated
        central.state = CBManagerState.poweredOn
        manager.centralManagerDidUpdateState(central)
        XCTAssertTrue(central.scanned, "central did not scan for peripherals")
    }

    // TODO: - Add more test cases

}

class MockViewController: ViewController {
    override func writeData(_ data: Array<Double>) {}
}

class MockCBCentralManager: CBCentralManager {
    var scanned = false
    
    override var state: CBManagerState {
        get {
            return self.state
        }
        set(state) {
            self.state = state
        }
    }
    
    override func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil) {
        scanned = true
    }
    
}

class MockCBPeripheral: CBPeripheral {
    override var state: CBPeripheralState {
        get {
            return self.state
        }
        set(state) {
            self.state = state
        }
    }
}

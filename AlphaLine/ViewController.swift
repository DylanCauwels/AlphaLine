//
//  ViewController.swift
//  AlphaLine
//
//  Created by Dylan Cauwels on 2/5/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import UIKit
import CoreBluetooth

// MARK: - Main Storyboard
class ViewController: UIViewController {
    let imageConfiguration = UIImage.SymbolConfiguration(scale: .small)
    
    var appDelegate: AppDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        self.bluetooth = BluetoothManager(view: self)
        self.appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    }

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
    
    func formatBTImage(color: UIColor) {
        BTSymbol.image = getSymbol(color: color, symbol: "dot.radiowaves.left.and.right")
        BTSymbol.alpha = 1.0
    }
    
    var deviceName: String?
    
    // TODO: refactor method to produce symbol with diff colors
    func changeBTState(_ newStatus: BluetoothPairingState, _ oldStatus: BluetoothPairingState) {
        switch newStatus {
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
                iconTimer?.invalidate()
                self.formatBTImage(color: .systemBlue)
                UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                  self.BTSymbol.alpha = 1.0
                }, completion: nil)
            case .transitioned:
                progressBar.removeFromSuperview()
                if let device = deviceName {
                    loadingMessage.text = device
                } else {
                    loadingMessage.text = "AlphaLine Prototype v1.12"
                }
                //TODO: have the Subview resize instead of just centering the content within the adjusted content subview
                BTSubview.center = CGPoint(x: BTView.frame.size.width  / 2, y: BTView.frame.size.height / 2)
            case .healthy:
                if let timer = iconTimer {stopTimer(timer: timer)}
                formatBTImage(color: .systemBlue)
            case .reconnecting:
                formatBTImage(color: .systemYellow)
                iconTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(blink), userInfo: self.BTSymbol, repeats: true)
            case .error:
                if let timer = iconTimer {stopTimer(timer: timer)}
                formatBTImage(color: .systemGray)
        }
    }
    
    
    // MARK: Battery Subview
    @IBOutlet weak var batteryView: UIView!
    @IBOutlet weak var batteryImage: UIImageView!
    @IBOutlet weak var batteryLabel: UILabel!
    
    var batteryTimer: Timer?
    
    // TODO: refactor into single border change method
    func formatBattery() {
        formatView(view: batteryView)
        formatBatteryImage(color: .systemGray, symbol: "battery.100")
    }
    
    func formatBatteryImage(color: UIColor, symbol: String) {
        batteryImage.image = getSymbol(color: color, symbol: symbol)
        batteryImage.alpha = 1.0
    }
    
    func changeBatteryState (_ newState: DeviceBatteryState, _ oldState: DeviceBatteryState) {
        switch newState {
        case .searching:
            formatBatteryImage(color: .systemGray, symbol: "battery.100")
            batteryTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(blink), userInfo: self.batteryImage, repeats: true)
            batteryLabel.text = nil
        case .high:
            stopTimer(timer: batteryTimer!)
            formatBatteryImage(color: .green, symbol: "battery.100")
            setLabel("100  |  95  |  98  |  96  |  92  |  95  |  97")
        case .low:
            formatBatteryImage(color: .orange, symbol: "battery.25")
            batteryTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(blink), userInfo: self.batteryImage, repeats: true)
            setLabel("23  |  25  |  30  |  21  |  27  |  26  |  30")
        case .dead:
            stopTimer(timer: batteryTimer!)
            formatBatteryImage(color: .red, symbol: "battery.0")
            batteryLabel.text = nil
        }
    }
    
    func setLabel(_ string: String) {
        batteryLabel.attributedText = attributedString(from: string, nonBoldRange: NSMakeRange(5, string.count-5))
    }
    
    func attributedString(from string: String, nonBoldRange: NSRange?) -> NSAttributedString {
        let fontSize = UIFont.systemFontSize
        let attrs = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: fontSize),
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
        let nonBoldAttribute = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize),
        ]
        let attrStr = NSMutableAttributedString(string: string, attributes: attrs)
        if let range = nonBoldRange {
            attrStr.setAttributes(nonBoldAttribute, range: range)
        }
        return attrStr
    }
    
    // MARK: Testing Subview
    @IBOutlet weak var testView: UIView!
    
    private var BTState: BluetoothPairingState?
    
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
        changeBTState(BTState!, .searching)
    }
    
    private var batteryState: DeviceBatteryState?
    @IBAction func testBattery(_ sender: Any) {
        var oldValue: DeviceBatteryState
        if let state = batteryState {
            oldValue = batteryState!
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
            oldValue = .searching
            batteryState = .searching
        }
        changeBatteryState(batteryState!, oldValue)
    }
    
    @IBAction func testBackView(_ sender: Any) {
        var meas = measurement([-25.0, -20.0, -15.0, -10.0, -5.0, 5.0])
        // Once anglesToPoints is completed replace this with the next line
//        meas.populateMeasurement(height: backView.frame.height, width: backView.frame.width)
        meas.toPoints(vertSpacing: backView.frame.height*0.175, horizSpacing: backView.frame.width*0.2, height: backView.frame.height, width: backView.frame.width)
        dataHub!.addData(data: meas)
        dataHub!.ingestData()
    }
    
    @IBAction func testData(_ sender: Any) {
        writeData(String(arc4random()))
    }
    
    func formatTesting() {
        formatView(view: testView)
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
    
    func logAngles(_ newAngles: [Double], _ oldAngles: [Double]) {
        var arr: Array<String> = []
        newAngles.forEach { angle in
            arr.append(String(format: "%.1f", angle))
        }
        writeData(arr.joined(separator: ","))
    }
    
    // writes data to the textbox with datetime
    func writeData(_ data: String) {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        // compiling message
        let datetime: String = String(hour) + ":" + String(minutes) + ":" + String(seconds)
        let received: String = "Data: " + String(data) + " \n\tReceived At: " + datetime + "\n"
        writeMessage(message: received)
    }
    
    var data: [String] = []
    // writes message to the dataBox
    func writeMessage(message: String) {
        if data.count >= 10 {
            data.remove(at: data.count-1)
        }
        data.insert(message, at: 0)
        var finalMessage: String = ""
        for message: String in  data {
            finalMessage += message
        }
        dataBox.text = finalMessage
    }
    
    // MARK: - Back View
    @IBOutlet weak var backView: BackView!
    var dataHub: DataHub?
    
    func formatBackView() {
        self.dataHub = DataHub(backView: backView!)
        formatView(view: backView)
    }
    
    // MARK: - Main
    override func viewDidLoad() {
        // gives access to main view property before its on screen
        super.viewDidLoad()
        // subscribe to bt status updates, device battery level updates
        let initialStatus = self.appDelegate?.bluetooth?.subscribeToStatus(observer: self, block: self.changeBTState)
        changeBTState(initialStatus!, BluetoothPairingState.error)
        let initialBattLevel = self.appDelegate?.bluetooth?.subscribeToBatteryLevel(observer: self, block: self.changeBatteryState)
        changeBatteryState(initialBattLevel!, .searching)
        _ = self.appDelegate?.bluetooth?.subscribeToAngles(observer: self, block: self.logAngles)
        
        // UI Commands
        formatBT()
        formatBattery()
        formatTesting()
        formatNetwork()
        formatBackView()
        
        // subscribe datahub to angles
        _ = self.appDelegate?.bluetooth?.subscribeToAngles(observer: dataHub!, block: dataHub!.updateDrawing)
        
    }
}

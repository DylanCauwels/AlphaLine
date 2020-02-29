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
        } else {
            print("battery state uninitialized")
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
    
    @IBAction func testBackView(_ sender: Any) {
        var meas = measurement()
        meas.populateMeasurement(height: backView.frame.height, width: backView.frame.width)
        dataHub!.addData(data: meas)
        dataHub!.ingestData()
    }
    
    @IBAction func testData(_ sender: Any) {
        writeData(data: arc4random())
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
        // UI Commands
        formatBT()
        formatBattery()
        formatTesting()
        formatNetwork()
        formatBackView()
        
    }
}

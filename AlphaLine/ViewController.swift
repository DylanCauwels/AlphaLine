//
//  ViewController.swift
//  AlphaLine
//
//  Created by Dylan Cauwels on 2/5/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import UIKit
import CoreBluetooth

// order of sensor locations as sent by peripheral
let Locations = ["A1", "A2", "A3", "A4", "Left", "Right"]

let dummyStr = "{1,2,3,4,5,6}"

class ViewController: UIViewController {
    
    var bleManager: BTManager?
    
    @IBAction func buttonPressed(_ sender: Any) {
        writeData([Double(arc4random()),Double(arc4random()), Double(arc4random()), Double(arc4random()), Double(arc4random()), Double(arc4random())])
    }
    
    @IBOutlet weak var DataLabel: UILabel!
    
    @IBOutlet weak var textbox: UITextView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.bleManager = BTManager(view: self)
    }
        
    func convertArrtoString(array: Array<Double>) -> String {
        var returnable = "["
        for value in array {
            returnable = returnable + String(value) + ","
        }
        return returnable + "]"
    }
    
    // writes data to the textbox with datetime
    func writeData(_ data:Array<Double>) {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        // compiling message
        let datetime: String = String(hour) + ":" + String(minutes) + ":" + String(seconds)
        let received: String = "\nData: " + convertArrtoString(array: data) + " \n\tReceived At: " + datetime
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
    }
    
}

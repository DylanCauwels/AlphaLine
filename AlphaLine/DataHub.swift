//
//  DataHub.swift
//  AlphaLine
//
//  Created by Dylan Cauwels on 2/17/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import Foundation
import UIKit

struct measurement {
    // raw quaternian data
    var quaternians: [Double]
    
    // quaternian data converted to angles
    var angles: [Double]
//        var angels: [(Double, Double)] = []
    
    // final positional data post-conversion
    var points: [CGPoint]
    let timestamp: Date
    var constraintsViolated: Bool
    init() {
        self.quaternians = [] // magic
        self.angles = [] // len 6
        self.points = [] // len 7
        self.timestamp = Date()
        self.constraintsViolated = false
    }
    
    // testing function for basic data display
    mutating func populateMeasurement(height: CGFloat, width: CGFloat){
      self.points = [CGPoint(x: width * 0.52, y: height * 0.25),      // 1
                         CGPoint(x: width * 0.53, y: height * 0.4),   // 2
                         CGPoint(x: width * 0.51, y: height * 0.55),  // 3
                         CGPoint(x: width * 0.52, y: height * 0.7),   // 4
                         CGPoint(x: width * 0.495, y: height * 0.85), // 5
                         CGPoint(x: width * 0.65, y: height * 0.84),  // 6
                         CGPoint(x: width * 0.35, y: height * 0.86)]  // 7
    }
    
    mutating func populateAngles(angles: [Double]) {
        self.angles = angles
    }
    
    // convert angle values to point values
    mutating func toPoints(vertSpacing: Double, horizSpacing: Double, height: CGFloat, width: CGFloat) {
        // build from 5 outward to 6, 7
        
        // build from 5 upward to 4 -> 3 -> 2 -> 1
    }
    
    // convert quaternian values to angle values
    mutating func toAngles() {}
    
}

class DataHub {
    let defaultColors: [UIColor] = [.systemBlue, .systemBlue, .systemBlue, .systemBlue, .systemBlue, .systemBlue, .systemBlue]
    
    let trainingColors: [UIColor] = [.systemGray, .systemGray, .systemGray, .systemGray, .systemGray, .systemGray, .systemGray]
    
    let q:Queue<measurement>
//    var constraints
    enum processType {
        case training, constrained, free;
    }
    var mode: processType
    let view: BackView
    
    init(backView: BackView) {
        q = Queue()
        mode = .free
        view = backView
    }
    
    func addData(data: measurement) {
        q.enqueue(key: data)
    }
    
    func ingestData() {
        if let data = q.dequeue() {
            switch mode {
                // constraints are currently being set by the data
                case .training:
                    setConstraints(data: data)
                    view.drawData(data: data.points, colors: trainingColors)
                // constraints have been defined and need to be checked against
                case .constrained:
                    view.drawData(data: data.points, colors: checkConstraints(data: data) ?? defaultColors)
                // diagnostics mode, no pre/post-processing required
                case .free:
                    view.drawData(data: data.points, colors: defaultColors)
            }
        } else {
            // TODO: change to thrown exception
            print("queue empty, no data to process")
        }
    }
    
    // TODO: implement
    // modifies constraings to include passed values
    func setConstraints(data: measurement) {}
    
    // checks data values against constraints to generate health colorset and triggers violation actions if necessary
    func checkConstraints(data: measurement) -> [UIColor]? {
        return defaultColors
    }
}

public class LinkedList<T> {
    var data: T
    var next: LinkedList?
    public init(data: T){
        self.data = data
    }
}

public class Queue<T> {
    typealias LLNode = LinkedList<T>
    var head: LLNode!
    public var isEmpty: Bool { return head == nil }
    var first: LLNode? { return head }
    var last: LLNode? {
        if var node = self.head {
            while case let next? = node.next {
                node = next
            }
            return node
        } else {
            return nil
        }
    }

    func enqueue(key: T) {
        let nextItem = LLNode(data: key)
        if let lastNode = last {
            lastNode.next = nextItem
        } else {
            head = nextItem
        }
    }
    func dequeue() -> T? {
        if self.head?.data == nil { return nil  }
        let temp = head
        if let nextItem = self.head?.next {
            head = nextItem
        } else {
            head = nil
        }
        return temp?.data
    }
}


//
//  BackView.swift
//  AlphaLine
//
//  Created by Dylan Cauwels on 2/13/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

// Angle Placement
/*
       x
       | 1
       x
       | 2
       x
       | 3
       x
       | 4
 ==x===x===x==
     5 | 6
 */

// Sensor Placement
/*
      x 1
      |
      x 2
      |
      x 3
      |
      x 4
      |
==x===x===x==
  4   |5  7
*/

import UIKit

struct arc {
    let startPoint: CGPoint
    let endPoint:  CGPoint
    let color: CGColor
}

class BackView: UIView {    
    var data: [CGPoint]?
    var colors: [UIColor]?
    var width: CGFloat?
    var height: CGFloat?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.width = frame.size.width
        self.height = frame.size.height
        self.data = []
        self.colors = []
    }
    
    func drawCircle(center: CGPoint, radius: CGFloat, color: UIColor, width: CGFloat) {
        if let context = UIGraphicsGetCurrentContext() {
            context.setLineWidth(width)
            color.set()
            context.addArc(center: center, radius: radius, startAngle: 0.0, endAngle: .pi * 2.0, clockwise: true)
            context.strokePath()
        }
    }
    
    func drawLine(start: CGPoint, end: CGPoint) {
        if let context = UIGraphicsGetCurrentContext() {
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
        }
    }
    
    func drawOutlines() {
        // .move and .addLine
        if let context = UIGraphicsGetCurrentContext() {
            context.setLineWidth(1.5)
            UIColor(red:225/255, green:225/255, blue:225/255, alpha: 1).set()
            print(NSLayoutConstraint.Attribute.centerX.rawValue)
            print(self.width! * 0.5)
            drawLine(start: CGPoint(x: self.width! * 0.25, y: self.height! * 0.85), end: CGPoint(x: self.width! * 0.85, y: self.height! * 0.85))
            drawLine(start: CGPoint(x: self.width! * 0.55, y: self.height! * 0.1), end: CGPoint(x: self.width! * 0.55, y: self.height! * 0.95))
            context.strokePath()
        }
    }
    
    func drawData(data: [CGPoint], colors: [UIColor]) {
        self.data = data
        self.colors = colors
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
//        print("redrawing view")
        drawOutlines()
        for (index, point) in data!.enumerated(){
            drawCircle(center: point, radius: 5, color: colors![index], width: 1.5)
        }
    }
}

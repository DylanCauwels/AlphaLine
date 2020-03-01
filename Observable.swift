//
//  Observable.swift
//  AlphaLine
//
//  Created by Jarrad Cisco on 2/19/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import Foundation

protocol Observable {
    associatedtype T
    var value: T {get set}
    
    func subscribe(observer: AnyObject, block: @escaping (_ newVal: T, _ oldVal: T) -> ())
    func unsubscribe(observer: AnyObject)
}

//
//  ObservableObject.swift
//  AlphaLine
//
//  Created by Jarrad Cisco on 2/19/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import Foundation

public final class ObservableObject<T>: NSObject, Observable {
    typealias ObserverBlock = (_ newValue: T, _ oldValue: T) -> ()
    typealias ObserversEntry = (observer: AnyObject, block: ObserverBlock)
    private var observers: Array<ObserversEntry>
    
    var value: T {
        didSet {
            observers.forEach { (entry: ObserversEntry) in
            let (_, block) = entry
            block(value, oldValue)
            }
        }
    }
    
    init(_ value: T) {
        self.value = value
        observers = []
    }
    
    func subscribe(observer: AnyObject, block: @escaping ObserverBlock) {
        let entry: ObserversEntry = (observer: observer, block: block)
        observers.append(entry)
    }
    
    func unsubscribe(observer: AnyObject) {
        let filtered = observers.filter { entry in
            let (owner, _) = entry
            return owner !== observer
        }

        observers = filtered
    }
}

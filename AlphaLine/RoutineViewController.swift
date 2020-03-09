//
//  CustomController.swift
//  AlphaLine
//
//  Created by Dylan Cauwels on 2/15/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import UIKit

// view controller for starting workout tab
class RoutineViewController: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    let items = ["0", "1", "2", "3", "4", "5", "6", "7", "8"]
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RoutineCell", for: indexPath) as! RoutineCollectionViewCell
        cell.centerLabel.text = items[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.item)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkTitleBarPosition()
    }
    
    var def:UIImage?
    
    @IBOutlet var titleBar: UINavigationBar!
    @IBOutlet var scrollView: UIScrollView!
    
    func checkTitleBarPosition() {
        if (scrollView.contentOffset.y < 8 ) {
            self.titleBar?.shadowImage = UIImage()
            self.titleBar?.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]

        } else {
            self.titleBar?.shadowImage = nil
            self.titleBar?.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.black]
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        checkTitleBarPosition()
    }
}

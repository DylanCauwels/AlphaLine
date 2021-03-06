//
//  HistoryViewController.swift
//  AlphaLine
//
//  Created by Dylan Cauwels on 3/1/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    let items = ["0", "1", "2", "3", "4", "5", "6", "7", "8"]
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("making Item at " + String(indexPath.item))
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HistoryCell", for: indexPath) as! HistoryCollectionViewCell
        cell.centerLabel.text = items[indexPath.item]
        cell.centerLabel.textColor = .white
        cell.backgroundColor = .black
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.item)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        checkTitleBarPosition()
    }
    
    var def:UIImage?
    
    @IBOutlet var titleBar: UINavigationBar!
    @IBOutlet var collectionView: UICollectionView!
    
    func checkTitleBarPosition() {
        if (collectionView.contentOffset.y < 8 ) {
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

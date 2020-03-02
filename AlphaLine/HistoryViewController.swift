//
//  HistoryViewController.swift
//  AlphaLine
//
//  Created by Dylan Cauwels on 3/1/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController, UIScrollViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        def = self.titleBar!.shadowImage
        self.titleBar?.shadowImage = UIImage()
        self.titleBar?.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
    }
    
    var def:UIImage?
    
    @IBOutlet var titleBar: UINavigationBar!
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y < 16 ) {
            self.titleBar?.shadowImage = UIImage()
            self.titleBar?.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]

        } else {
            self.titleBar?.shadowImage = def
            self.titleBar?.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.black]
        }
    }
}

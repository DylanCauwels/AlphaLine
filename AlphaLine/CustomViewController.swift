//
//  CustomController.swift
//  AlphaLine
//
//  Created by Dylan Cauwels on 2/15/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import UIKit

// view controller for starting workout tab
class CustomViewController: UIViewController {

    @IBOutlet weak var backView: BackView!
    
    @IBOutlet weak var backDisplay: BackView!
    
    func formatView(view: UIView) {
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
        view.layer.cornerRadius = 10
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        formatView(view: backDisplay)
//        _ = DataHub(backView: backView)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

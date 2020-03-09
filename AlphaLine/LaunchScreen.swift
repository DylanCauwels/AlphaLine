//
//  LaunchScreenViewController.swift
//  AlphaLine
//
//  Created by Dylan Cauwels on 3/8/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import UIKit
import SwiftyGif

class LaunchScreen: UIViewController {

    let logoAnimationView = LogoAnimationView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(logoAnimationView)
        logoAnimationView.pinEdgesToSuperView()
        logoAnimationView.logoGifImageView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let seconds = 1.5
        self.logoAnimationView.logoGifImageView.stopAnimating()
        // delay to prevent gif from stuttering due to object load
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.logoAnimationView.logoGifImageView.startAnimatingGif()
        }
    }
}

extension LaunchScreen: SwiftyGifDelegate {
    func gifDidStop(sender: UIImageView) {
        performSegue(withIdentifier: "transitionDone", sender: nil)
    }
}

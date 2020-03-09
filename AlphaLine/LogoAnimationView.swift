//
//  LogoAnimationView.swift
//  AlphaLine
//
//  Created by Dylan Cauwels on 3/8/20.
//  Copyright © 2020 Group 6. All rights reserved.
//

import UIKit
import SwiftyGif
class LogoAnimationView: UIView {
    
    let logoGifImageView: UIImageView = {
        guard let gifImage = try? UIImage(gifName: "LoadingGif.gif", levelOfIntegrity: .infinity) else {
            print("loading gif not found")
            return UIImageView()
        }
        return UIImageView(gifImage: gifImage, loopCount: 1)
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = UIColor(white: 246.0 / 255.0, alpha: 1)
        addSubview(logoGifImageView)
        logoGifImageView.pinEdgesToSuperView()
        logoGifImageView.stopAnimatingGif()
//        logoGifImageView.translatesAutoresizingMaskIntoConstraints = false
//        logoGifImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
//        logoGifImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}

extension UIView {
    func pinEdgesToSuperView() {
        guard let superView = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        leftAnchor.constraint(equalTo: superView.leftAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
        rightAnchor.constraint(equalTo: superView.rightAnchor).isActive = true
    }
    
}

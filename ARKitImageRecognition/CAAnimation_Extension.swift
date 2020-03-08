//
//  CAAnimation_Extension.swift
//  ARKitImageRecognition
//
//  Created by elumalai on 06/03/20.
//  Copyright © 2020 Jayven Nhan. All rights reserved.
//

import Foundation
import SceneKit

extension CAAnimation {
    class func animationWithSceneNamed(_ name: String) -> CAAnimation? {
        var animation: CAAnimation?
        if let scene = SCNScene(named: name) {
            scene.rootNode.enumerateChildNodes({ (child, stop) in
                if child.animationKeys.count > 0 {
                    animation = child.animation(forKey: child.animationKeys.first!)
                    stop.initialize(to: true)
                }
            })
        }
        return animation
    }
}

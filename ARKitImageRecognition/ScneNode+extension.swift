//
//  ScneNode+extension.swift
//  ARKitImageRecognition
//
//  Created by elumalai on 08/03/20.
//  Copyright © 2020 Jayven Nhan. All rights reserved.
//

import Foundation
import SceneKit

extension SCNNode {
    func play(sound: Sound) {
        self.runAction(SCNAction.playAudio(sound.audioSource, waitForCompletion: false))
    }
}

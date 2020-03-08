//
//  ViewController+Sound.swift
//  ARKitImageRecognition
//
//  Created by elumalai on 08/03/20.
//  Copyright © 2020 Jayven Nhan. All rights reserved.
//

import Foundation
import SceneKit


enum Sound: String {
    case start, left, right, straight, stairsUP, stairsDown, dontAskMe, contanctManager
    var filePath: String {
       return "HighRise.scnassets/Audio/\(self.rawValue).wav"
    }
    
    var audioSource: SCNAudioSource {
        if let sound = SCNAudioSource(fileNamed: self.filePath) {
          sound.isPositional = false
          sound.volume = 1
          sound.load()
          return sound
        } else {
            return SCNAudioSource()
        }
    }
}

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
    case welcome, start, left, right, straight, stairsUP, stairsDown, dontAskMe, introduction
    
    var filePath: String {
       return "start.wav"
    }
    var textToSpeech: String {
        switch self {
        case .welcome:
            return "welcome, please follow me to get into your desired destination"
        case .straight:
            return "come straight now"
        case .left, .right:
            return "turn \(self.rawValue)"
        case .stairsUP:
            return "climp up stairs along with me"
        case .stairsDown:
            return "climp Down stairs along with me"
        case .introduction:
            return "Hi glad to meet you, myself is kirobot version 1.0, say hi to me to continue"
        default:
            return "not defined"
        }
    }
    
    var audioSource: SCNAudioSource {
        if let sound = SCNAudioSource(fileNamed: self.filePath) {
          sound.isPositional = true
//          sound.volume = 1
          sound.load()
          return sound
        } else {
            return SCNAudioSource()
        }
    }
}

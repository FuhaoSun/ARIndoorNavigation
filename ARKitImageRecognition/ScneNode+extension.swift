//
//  ScneNode+extension.swift
//  ARKitImageRecognition
//
//  Created by elumalai on 08/03/20.
//  Copyright © 2020 Jayven Nhan. All rights reserved.
//

import Foundation
import SceneKit
import AVFoundation

extension SCNNode {
    
    func play(sound: Sound, _ customVoice: Bool = false, synthesizer: AVSpeechSynthesizer?) {
        
        if !customVoice, let synthesizer = synthesizer  {
            let utterance = AVSpeechUtterance(string: sound.textToSpeech)
            utterance.voice = AVSpeechSynthesisVoice()
            synthesizer.speak(utterance)
        } else {
            self.runAction(SCNAction.playAudio(sound.audioSource, waitForCompletion: false))
        }
        
    }
}

//
//  KeywordsSpeechService.swift
//  ARKitInteraction
//
//  Created by Martin Mitrevski on 16.12.18.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation

class KeywordsSpeechService: SpeechService {
    
    func action(for text: String) -> SpeechAction? {
        let lowercased = text.lowercased()
        
        
        
        let words: [String] = lowercased
            .components(separatedBy: .punctuationCharacters)
            .joined()
            .components(separatedBy: .whitespaces)
            .filter{ !$0.isEmpty }
        return action(for: words)
    }
    
    private func action(for words: [String]) -> SpeechAction? {
        if (words.contains("hello") || words.contains("hi")) /* && words.contains("kirrobot") || words.contains("kirobot") */ {
            return .greetings
        }
        
        if words.contains("stop") {
            return .stop
        }
        
        if words.contains("start") {
            return .start
        }
        
        return .question
    }
    
}

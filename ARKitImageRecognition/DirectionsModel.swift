//
//  DirectionsModel.swift
//  ARKitImageRecognition
//
//  Created by elumalai on 06/03/20.
//  Copyright © 2020 Jayven Nhan. All rights reserved.
//

import Foundation

struct Department: Codable {
    let CSE: DirectionsModel
    let IT: DirectionsModel
}

struct DirectionsModel: Codable {
    let directions: [DirectionItem]
}


struct DirectionItem: Codable {
    let name: Direction
    let distance: Float
    var rotation: Double?
    var slope: Slope?
}

enum Slope: String, Codable {
    case up, down
}

enum Direction: String, Codable {
    case initial, right, left, straight, up, down
}



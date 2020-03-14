//
//  ViewController.swift
//  Image Recognition
//
//  Created by Jayven Nhan on 3/20/18.
//  Copyright © 2018 Jayven Nhan. All rights reserved.
//

import UIKit
import ARKit
import Speech

class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var recordingButton: UIButton!
    
    /// Speech variables
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer! =
        SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    @IBOutlet weak var recognizedText: UITextView!
    var cancelCalled = false
    var audioSession = AVAudioSession.sharedInstance()
    var timer: Timer?
    let speechService: SpeechService = KeywordsSpeechService()
    let useCustomVoice = false
    var isVoiceOverDone: Bool = false {
        didSet(newValue) {
            pandasNode.isPaused = newValue
        }
    }
    var isGreeted: Bool = false
    
    let synthesizer = AVSpeechSynthesizer()
    
    
    //Animation variables
    let fadeDuration: TimeInterval = 0.3
    let rotateDuration: TimeInterval = 3
    let waitDuration: TimeInterval = 0.5
    let speedRatio: Float = (0.6 / 60)
    let stairsSpeedRatio: Float = (0.2 / 70)
    let constantDistance: Float = 3.0
    private var walkAnimation: CAAnimation!
    
    var hasDirectionEnd = false
    var directions: [DirectionItem]?
    var directionsEndStatus: [Bool] = []
    var pandasInitialPosition: Float?
    
    var isPandasCharectorAdded = false
    var initalAngle: Float = 0
    
    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
    
    lazy var pandasNode: SCNNode = {
        guard let scene = SCNScene(named: "panda.scn"),
            let node = scene.rootNode.childNode(withName: "panda", recursively: false) else { return SCNNode() }
        let scaleFactor  = 0.9
        node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        return node
    }()
    
    lazy var departmentsDB: Department = {
        let resourceURL = Bundle.main.url(forResource: "Directions", withExtension: "json")!
        let modelStringData = try! Data(contentsOf: resourceURL)
        let departments = try! JSONDecoder().decode(Department.self, from: modelStringData)
        return departments
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session.delegate = self
        synthesizer.delegate = self
        speechRecognizer.delegate = self
        checkPermissions()
        
        configureLighting()
        loadAnimation()
        
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        resetTrackingConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    @IBAction func resetButtonDidTouch(_ sender: UIBarButtonItem) {
        resetTrackingConfiguration()
        pandasNode.position = SCNVector3(0, 0, 0)
    }
    
    func resetTrackingConfiguration() {
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else { return }
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        sceneView.session.run(configuration, options: options)
        directionsEndStatus = []
        isVoiceOverDone = false
        isGreeted = false
        directions = nil
        //        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        
        label.text = "Move camera around to detect images"
    }
    
    func loadAnimation() {
        walkAnimation = CAAnimation.animationWithSceneNamed("walk.scn")
        walkAnimation.usesSceneTimeBase = false
        walkAnimation.fadeInDuration = 0.3
        walkAnimation.repeatCount = Float.infinity
    }
    
    func getDirections(withImageName name: String) -> [DirectionItem]? {
        var directions: [DirectionItem]?
        switch name {
        case "qrCode":
            directions = departmentsDB.CSE.directions
        default:
            break
        }
        return directions
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            guard let imageAnchor = anchor as? ARImageAnchor,
                let imageName = imageAnchor.referenceImage.name else { return }
            node.addChildNode(self.pandasNode)
            self.pandasNode.addAnimation(self.walkAnimation, forKey: "walk")
            self.pandasNode.isPaused = true
            self.isPandasCharectorAdded = true
            self.directions = self.getDirections(withImageName: imageName)
            self.pandasNode.play(sound: .introduction, synthesizer: self.synthesizer)
            
            self.label.text = "Image detected: \"\(imageName)\""
        }
    }
    
}

extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let directions = directions, directions.count > directionsEndStatus.count else {
            pandasNode.removeFromParentNode()
            return
        }
        
        let cameraNode = sceneView.pointOfView!
        let directionDetail = directions[directionsEndStatus.count]
        var isPersonMoving = false
        
        switch directionDetail.name {
            
        case .initial:
            
            if pandasInitialPosition == nil && isGreeted {
                pandasInitialPosition = pandasNode.position.z
                self.pandasNode.play(sound: .welcome, useCustomVoice, synthesizer: synthesizer)
            }
            
            if isVoiceOverDone {
                prepareForNextMovement(rotationalAngle: directionDetail.rotation ?? 180)
            }
            
        case .straight:
            //if the distance between charector and user camera is more than 3 meters we presume that user is not moving
            isPersonMoving = cameraNode.position.z - pandasNode.position.z < constantDistance
            
            if isVoiceOverDone {
                moveTheObject(fromCurrent : { pandasNode.position.z },
                              directionDetail: directionDetail,
                              isPersonMoving,
                              transformFunction: { pandasNode.position.z -= speedRatio })
                
                //for stairs
                checkStairs(for: directionDetail)
            } else {
                if pandasInitialPosition == nil {
                    pandasInitialPosition = pandasNode.position.z
                    playAudio(for: directionDetail, sound: .straight)
                }
            }
            
        case .left:
            isPersonMoving = cameraNode.position.x - pandasNode.position.x < constantDistance
            
            if isVoiceOverDone {
                moveTheObject(fromCurrent : { pandasNode.position.x },
                              directionDetail: directionDetail,
                              isPersonMoving,
                              transformFunction: { pandasNode.position.x -= speedRatio })
                
                //for stairs
                checkStairs(for: directionDetail)
                
                DispatchQueue.main.async {
                    self.label.text = "straigt - \(cameraNode.position.x - self.pandasNode.position.x)"
                    
                }
            } else {
                if pandasInitialPosition == nil {
                    pandasInitialPosition = pandasNode.position.x
                    playAudio(for: directionDetail, sound: .left)
                }
            }
            
        case .right:
            isPersonMoving = cameraNode.position.x - pandasNode.position.x < constantDistance
            
            if isVoiceOverDone {
                moveTheObject(fromCurrent : { pandasNode.position.x },
                              directionDetail: directionDetail,
                              isPersonMoving,
                              transformFunction: { pandasNode.position.x += speedRatio })
                
                //for stairs
                checkStairs(for: directionDetail)
                
                DispatchQueue.main.async {
                    self.label.text = "straigt - \(cameraNode.position.x - self.pandasNode.position.x)"
                    
                }
            } else {
                if pandasInitialPosition == nil {
                    pandasInitialPosition = pandasNode.position.x
                    playAudio(for: directionDetail, sound: .left)
                }
            }
            
        default:
            print("test")
        }
    }
    
    func moveTheObject(fromCurrent currentPosition: ()->(Float),
                       directionDetail: DirectionItem,
                       _ isPersonMoving: Bool,
                       transformFunction: () -> ()) {
        let movedPosition = abs(currentPosition() - pandasInitialPosition!)
        pandasNode.isPaused = !(isPandasCharectorAdded && isPersonMoving)
        
        if movedPosition <= directionDetail.distance && !pandasNode.isPaused {
            transformFunction()
        } else {
            prepareForNextMovement(rotationalAngle: directionDetail.rotation)
        }
    }
    
    func prepareForNextMovement(rotationalAngle: Double?) {
        if let rotation = rotationalAngle {
            //            let rotate = SCNAction.rotateBy(x: CGFloat(deg2rad(rotation)), y: 0, z: 0, duration: 1)
            
            pandasNode.eulerAngles.y = Float(deg2rad(rotation))
        }
        pandasInitialPosition = nil
        isVoiceOverDone = false
        directionsEndStatus.append(true)
    }
    
    
    func checkStairs(for directionDetail: DirectionItem) {
        if let slope = directionDetail.slope {
            if slope == .up {
                pandasNode.position.y += stairsSpeedRatio
            } else {
                pandasNode.position.y -= stairsSpeedRatio
            }
        }
    }
    
    
    
    func playAudio(for directionDetail: DirectionItem, sound: Sound) {
        if let slope = directionDetail.slope {
            if slope == .up {
                self.pandasNode.play(sound: .stairsUP, useCustomVoice, synthesizer: synthesizer)
            } else {
                self.pandasNode.play(sound: .stairsDown, useCustomVoice, synthesizer: synthesizer)
            }
        } else {
            self.pandasNode.play(sound: sound, useCustomVoice, synthesizer: synthesizer)
        }
    }
    
}

extension ViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        
        if isGreeted {
            isVoiceOverDone = true
        }
        
    }
}




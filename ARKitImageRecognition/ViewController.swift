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
    
    //Animation variables
    let fadeDuration: TimeInterval = 0.3
    let rotateDuration: TimeInterval = 3
    let waitDuration: TimeInterval = 0.5
    let speedRatio: Float = (0.6 / 60)
    let stairsSpeedRatio: Float = (0.2 / 50)
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
        node.eulerAngles = SCNVector3(0,deg2rad(180), 0)
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
            self.isPandasCharectorAdded = true
            self.directions = self.getDirections(withImageName: imageName)
            
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
            
        case .straight:
            //if the distance between charector and user camera is more than 3 meters we presume that user is not moving
            isPersonMoving = cameraNode.position.z - pandasNode.position.z < constantDistance
            pandasInitialPosition = pandasInitialPosition ?? pandasNode.position.z
            moveTheObject(fromCurrent : { pandasNode.position.z },
                          directionDetail: directionDetail,
                          isPersonMoving,
                          transformFunction: { pandasNode.position.z -= speedRatio })
            
            if directionDetail.stairs != nil {
                pandasNode.position.y += stairsSpeedRatio
            }
            
            
             DispatchQueue.main.async {
                self.label.text = "straigt - \(cameraNode.position.z - self.pandasNode.position.z)"

                }
            
        case .left:
            isPersonMoving = cameraNode.position.x - pandasNode.position.x < constantDistance
            pandasInitialPosition = pandasInitialPosition ?? pandasNode.position.x
            moveTheObject(fromCurrent : { pandasNode.position.x },
                          directionDetail: directionDetail,
                          isPersonMoving,
                          transformFunction: { pandasNode.position.x -= speedRatio })
            DispatchQueue.main.async {
                self.label.text = "left - count \(self.directionsEndStatus.count)"
            }
            
        case .right:
            isPersonMoving = cameraNode.position.x - pandasNode.position.x < constantDistance
            pandasInitialPosition = pandasInitialPosition ?? pandasNode.position.x
            moveTheObject(fromCurrent : { pandasNode.position.x },
                          directionDetail: directionDetail,
                          isPersonMoving,
                          transformFunction: { pandasNode.position.x += speedRatio })
            DispatchQueue.main.async {
                self.label.text = "right - count \(self.directionsEndStatus.count)"
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
        directionsEndStatus.append(true)
    }
    
}




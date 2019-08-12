//
//  ViewController.swift
//  Nano9_Arkit
//
//  Created by Stefan V. de Moraes on 21/11/18.
//  Copyright © 2018 Stefan V. de Moraes. All rights reserved.
//

import UIKit
import ARKit

class ARViewController: UIViewController {
    
    // Create a session view
    @IBOutlet weak var arSceneView: ARSCNView!
    @IBOutlet weak var casaBtn: UIButton!
    @IBOutlet weak var connectionsLabel: UILabel!
    
     let scene2 = SCNScene(named: "art.scnassets/box.scn")!
    
    var directionalLightNode: SCNNode?
    var ambientLightNode: SCNNode?
    var container: SCNNode!
    
    var badgerVoice = "Haya.wav"
    
    var trackerNode: SCNNode?
    var foundSurface = false
    var tracking = true
    
    var ballColor: UIColor = .brown
    var ponto: CGPoint!
    
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    
    let colorService = ColorService()
    
    override func viewDidAppear(_ animated: Bool) {
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Code
        
        // Set the view's delegate
        arSceneView.delegate = self
        colorService.delegate = self
        
        self.arSceneView.debugOptions = [/*ARSCNDebugOptions.showFeaturePoints,*/ ARSCNDebugOptions.showWorldOrigin]
        self.arSceneView.autoenablesDefaultLighting = true
        
        // Set the scene to the view
        arSceneView.scene = scene2
        container = arSceneView.scene.rootNode.childNode(withName: "container", recursively: false)!
        ponto = CGPoint(x: self.view.frame.midX, y: self.view.frame.midY)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configuration.planeDetection = .horizontal
        arSceneView.session.delegate = self
        guard let referenceImages =  ARReferenceObject.referenceObjects(inGroupNamed: "Consagrado", bundle: Bundle.main)
           else { return }
        configuration.detectionObjects = referenceImages
        
        configuration.detectionImages = ARReferenceImage.referenceImages(inGroupNamed: "Image", bundle: Bundle.main)
        
        configuration.maximumNumberOfTrackedImages = 1
        let opt: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]

        // Run the view's session
        self.arSceneView.session.run(configuration, options: opt)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        self.arSceneView.session.pause()
    }
    
    //Funções Auxiliares
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        if tracking {
            //Setar a Scene
            guard foundSurface else { return }
            let trackingPosition = trackerNode!.position
            trackerNode?.removeFromParentNode()
            //container = arSceneView.scene.rootNode.childNode(withName: "container", recursively: false)!
            container.position = trackingPosition
            container.isHidden = false
            ambientLightNode = container.childNode(withName: "ambient", recursively: false)
            directionalLightNode = container.childNode(withName: "directional", recursively: false)
            arSceneView.scene.physicsWorld.contactDelegate = self
            tracking = false
        } else {
            //Handler do Tiro
            guard foundSurface else { return } //1
            let trackingPosition = trackerNode!.position //2
            trackerNode?.removeFromParentNode()
            casaBtn.isHidden = false
            container.position = trackingPosition
            container.isHidden = false //3
            ambientLightNode = container.childNode(withName: "ambient", recursively: false)
            directionalLightNode = container.childNode(withName: "directional", recursively: false)
            tracking = false //4
            
            guard let frame = arSceneView.session.currentFrame else { return } //1
            let camMatrix = SCNMatrix4(frame.camera.transform)
            let direction = SCNVector3Make(-camMatrix.m31 * 5.0, -camMatrix.m32 * 10.0, -camMatrix.m33 * 5.0) //2
            let position = SCNVector3Make(camMatrix.m41, camMatrix.m42, camMatrix.m43) //3
            
            let ball = SCNSphere(radius: 0.05) //1
            ball.firstMaterial?.diffuse.contents = ballColor
            ball.firstMaterial?.emission.contents = ballColor //2
            let ballNode = SCNNode(geometry: ball)
            ballNode.position = position //3
            ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            ballNode.physicsBody?.categoryBitMask = 3
            ballNode.physicsBody?.contactTestBitMask = 1 //4
            arSceneView.scene.rootNode.addChildNode(ballNode)
            ballNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 10.0), SCNAction.removeFromParentNode()])) //5
            ballNode.physicsBody?.applyForce(direction, asImpulse: true) //6
        }
    }
    
    @IBAction func reset(_ sender: Any) {
        self.restartSession()
    }
    
    func restartSession()  {
        self.arSceneView.session.pause()
        self.arSceneView.scene.rootNode.enumerateChildNodes {(node, _) in
            node.removeFromParentNode()
            
        }
        self.arSceneView.scene = scene2
      
        self.arSceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    

    @IBAction func addCasa(_ sender: UIButton) {
        let x = randNum(firstNum: -0.4, secNum: 0.4)
        let y = randNum(firstNum: -0.4, secNum: 0.4)
        let z = randNum(firstNum: -0.4, secNum: 0.4)
        let nd = SCNNode()
        nd.geometry = SCNBox(width: 0.45, height: 0.45, length: 0.45, chamferRadius: 0.02)
        nd.geometry?.firstMaterial?.specular.contents = UIColor.white
        nd.geometry?.firstMaterial?.diffuse.contents = ballColor
        nd.physicsBody? = SCNPhysicsBody(type: .dynamic, shape: nil)
        nd.physicsBody?.categoryBitMask = 0x4
        nd.physicsBody?.contactTestBitMask = 1
        nd.physicsBody?.categoryBitMask = 1
        nd.physicsBody?.collisionBitMask = ~(0x4)
        nd.physicsBody?.isAffectedByGravity = true
        nd.position = SCNVector3(x, y, z)
        
        container.addChildNode(nd)
        
    }
    
    @IBAction func redTapped() {
        self.change(color: .red, voz: "Haya.wav")
        colorService.send(colorName: "red")
    }
    
    @IBAction func yellowTapped() {
        self.change(color: .yellow, voz: "oiChapa.wav")
        colorService.send(colorName: "yellow")
    }
    
    func change(color : UIColor, voz: String) {
        self.ballColor = color
        self.badgerVoice = voz
    }
}

func randNum(firstNum: CGFloat, secNum: CGFloat) -> CGFloat {
    
    return CGFloat(arc4random())/CGFloat(UINT32_MAX) * abs( firstNum - secNum) + min(firstNum, secNum)
}
//MARK: End ViewController

extension ARViewController: ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let lightEstimate = frame.lightEstimate else { return }
        guard !tracking else { return } //1
        ambientLightNode?.light?.intensity = lightEstimate.ambientIntensity * 0.4 //2
        directionalLightNode?.light?.intensity = lightEstimate.ambientIntensity
    }

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let ball = contact.nodeA.physicsBody!.contactTestBitMask == 3 ? contact.nodeA : contact.nodeB
        let explosion = SCNParticleSystem(named: "Explosion.scnp", inDirectory: nil)!
        let explosionNode = SCNNode()
        explosionNode.position = ball.presentation.position
        arSceneView.scene.rootNode.addChildNode(explosionNode)
        explosionNode.addParticleSystem(explosion)
        ball.removeFromParentNode()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        //Setar mapeanmento 3d
        let node = SCNNode()
        if let objAnchor = anchor as? ARObjectAnchor {
            let sceneURL = Bundle.main.url(forResource: "gnomeHouse", withExtension: "scn", subdirectory: "art.scnassets")!
            let referenceNode = SCNReferenceNode(url: sceneURL)!
            referenceNode.load()
            
            let hahaSource = SCNAudioSource(named: "Evil.wav")
            
            let action = SCNAction.rotate(by: 360 * CGFloat((Double.pi)/180), around: SCNVector3(x:1, y:0, z:0), duration: 2)
            let laught = SCNAction.playAudio(hahaSource!, waitForCompletion: true)
            
            referenceNode.position = SCNVector3Make(objAnchor.referenceObject.center.x - 0.036, objAnchor.referenceObject.center.y
                - 0.027, objAnchor.referenceObject.center.z)
            let fire = SCNParticleSystem(named: "Fogo.scnp", inDirectory: nil)!
            let fireNode = SCNNode()
            fireNode.addParticleSystem(fire)
            fireNode.particleSystems?.first?.birthLocation = (SCNParticleBirthLocation(rawValue: -6) ?? nil)!
            fireNode.position = SCNVector3Make(objAnchor.referenceObject.center.x, objAnchor.referenceObject.center.y
                + 0.082, objAnchor.referenceObject.center.z)
            node.addChildNode(fireNode)
            
            
            node.addChildNode(referenceNode)
            
            referenceNode.runAction(laught)
            referenceNode.runAction(action)
            
        }
        self.arSceneView.scene.rootNode.addChildNode(node)
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARImageAnchor {
        
        let chapaSource = SCNAudioSource(named: self.badgerVoice)
        let chapa = SCNAction.playAudio(chapaSource!, waitForCompletion: true)
        node.runAction(chapa)
        }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard tracking else { return } //1
        let hitTest = self.arSceneView.hitTest(self.ponto, types: .featurePoint)//2
        guard let result = hitTest.first else { return }
        let translation = SCNMatrix4(result.worldTransform)
        let position = SCNVector3Make(translation.m41, translation.m42, translation.m43) //3
        
        if trackerNode == nil { //1
            let plane = SCNPlane(width: 0.18, height: 0.18)
            plane.firstMaterial?.diffuse.contents = UIImage(named: "tracker.png")
            plane.firstMaterial?.isDoubleSided = true
            trackerNode = SCNNode(geometry: plane) //2
            trackerNode?.eulerAngles.x = -.pi * 0.5 //3
            self.arSceneView.scene.rootNode.addChildNode(self.trackerNode!) //4
            foundSurface = true
        }
        self.trackerNode?.position = position //5
    }
}

extension ARViewController : ColorServiceDelegate {
    
    func connectedDevicesChanged(manager: ColorService, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            self.connectionsLabel.text = "Connections: \(connectedDevices)"
        }
    }
    
    func colorChanged(manager: ColorService, colorString: String) {
        OperationQueue.main.addOperation {
            switch colorString {
            case "red":
                self.change(color: .red, voz: "Haya.wav")
            case "yellow":
                self.change(color: .yellow, voz: "oiChapa.wav")
            default:
                NSLog("%@", "Unknown color value received: \(colorString)")
            }
        }
    }
    
}

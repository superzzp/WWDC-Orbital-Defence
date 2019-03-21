import Foundation
import UIKit
import ARKit
import SpriteKit
import SceneKit


struct PhysicsMask {
    static let playerBullet = 0
    static let enemyBullet = 1
    static let enemy = 2
    static let player = 3
}

enum LaserType  {
    case player
    case enemy
}

public class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate,GameDelegate {
    
    var sceneView: ARSCNView!
    var plusButton: UIButton!
    var UFOs = [UFONode]()
    var lasers = [LaserNode]()
    
    //UI
    
    var groundNode : SKLabelNode!
    var scoreNode : SKLabelNode!
    var livesNode : SKLabelNode!
    var radarNode : SKShapeNode!
    var crosshair: SKSpriteNode!
    let sidePadding : CGFloat = 5

    //font
    lazy var paragraphStyle : NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.left
        return style
    }()
    
    lazy var stringAttributes : [NSAttributedString.Key : Any] = [.strokeColor : UIColor.black, .strokeWidth : -4, .foregroundColor: UIColor.white, .font : UIFont.systemFont(ofSize: 23, weight: .bold), .paragraphStyle : paragraphStyle]
    
    var bulletSpeed: Float = 50
    let session = ARSession()
    public var game = Game()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        game.delegate = self
        sceneView = ARSCNView(frame: CGRect(x: 0.0, y: 0.0, width: 1100, height: 1100))
        let scene = SCNScene()
        sceneView.scene = scene
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.delegate = self
        sceneView.session = session
        
        sceneView.session.delegate = self
        self.view = sceneView
        
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin,ARSCNDebugOptions.showFeaturePoints]
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        
        
        
        self.sceneView.session.run(configuration)
        
        sceneView.scene.physicsWorld.contactDelegate = self
        
        //setup overlay
        sceneView.overlaySKScene = SKScene(size: sceneView.bounds.size)
        sceneView.overlaySKScene?.scaleMode = .resizeFill
        
        
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        //create universe map and add its physics
        createUniverse()
        
        //populate 3 UFOs for testing
        addTargets()
        
        //add aiming cross indication
        addAimingCrossButton()
        
        //Setup labels
        setupLabels()
        
//        //add star particles
//        sceneView.scene.rootNode.addParticleSystem(SCNParticleSystem(named: "starsParticle", inDirectory: "/")!)
        
    }
    
    //add a portal when user tap on the ground
    //portal will contain the universe in it, start the game when user walk in the portal
    func addPortal(hitTestResult: ARHitTestResult) {
        let portalScene = SCNScene(named: "Portal.scn")
        let portalNode = portalScene!.rootNode.childNode(withName: "Portal", recursively: false)!
        let transform = hitTestResult.worldTransform
        let planeXposition = transform.columns.3.x
        let planeYposition = transform.columns.3.y
        let planeZposition = transform.columns.3.z
        portalNode.position =  SCNVector3(planeXposition, planeYposition, planeZposition)
        self.sceneView.scene.rootNode.addChildNode(portalNode)
        self.addPlane(nodeName: "roof", portalNode: portalNode, imageName: "top")
        self.addPlane(nodeName: "floor", portalNode: portalNode, imageName: "bottom")
        self.addWalls(nodeName: "backWall", portalNode: portalNode, imageName: "back")
        self.addWalls(nodeName: "sideWallA", portalNode: portalNode, imageName: "sideA")
        self.addWalls(nodeName: "sideWallB", portalNode: portalNode, imageName: "sideB")
        self.addWalls(nodeName: "sideDoorA", portalNode: portalNode, imageName: "sideDoorA")
        self.addWalls(nodeName: "sideDoorB", portalNode: portalNode, imageName: "sideDoorB")
        self.game.portalCreated = true
        //self.game.gameStart = true
    }
    
    
    //helper function for addPortal(), add walls for the portal
    //set the mask to be transparent, and set the wall behind it to render after the mask, so that the color of the mask and wall will mix together
    func addWalls(nodeName: String, portalNode: SCNNode, imageName: String) {
        let child = portalNode.childNode(withName: nodeName, recursively: true)
        child?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "\(imageName).png")
        child?.renderingOrder = 200
        if let mask = child?.childNode(withName: "mask", recursively: false) {
            mask.geometry?.firstMaterial?.transparency = 0.000001
        }
    }
    
    //helper function for addPortal(), add floor and ceiling for the portal
    func addPlane(nodeName: String, portalNode: SCNNode, imageName: String) {
        let child = portalNode.childNode(withName: nodeName, recursively: true)
        child?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "\(imageName).png")
        child?.renderingOrder = 200
    }
    
    
    //GameDelegate Functions
    func scoreDidChange() {
        scoreNode.attributedText = NSMutableAttributedString(string: "Enemies: \(game.totalUFOs - game.score)", attributes: stringAttributes)
        if game.score >= game.totalUFOs {
            game.winLoseFlag = true
            showFinish()
        }
    }
    
    func healthDidChange() {
        
        // change the number to emojis
        var i = 0
        var healthEmoji = ""
        while i<game.health {
            i = i+1
            healthEmoji += "♥️"
        }
        livesNode.attributedText = NSAttributedString(string: "Health: \(healthEmoji)", attributes: stringAttributes)
        if game.health <= 0 {
            game.winLoseFlag = false
            showFinish()
        }
    }
    
    //create the universe and planet nodes, and apply rotation and revolution
    func createUniverse(){
        let sun = SCNSphere(radius: 0.13)
        let sunNode = createPlanetNode(geometry: sun, position: SCNVector3(-1,0,0), diffuse: UIImage.init(named: "sun diffuse.jpg") , specular: nil, emission: nil, normal: nil)
        sunNode.addParticleSystem(SCNParticleSystem(named: "sparksParticle", inDirectory: "/")!)
        
        let earthParentNode = SCNNode()
        earthParentNode.position = SCNVector3(-1,0,0)
        
        //node for earth, around the sun
        let earth = SCNSphere(radius: 0.06)
        let earthNode = createPlanetNode(geometry: earth, position: SCNVector3(0.6,0,0), diffuse: UIImage.init(named: "earth diffuse.jpg") , specular: UIImage.init(named: "earth specular"), emission: UIImage.init(named: "earth emission"), normal: UIImage.init(named: "earth normal"))
        
        let moonParentNode = SCNNode()
        moonParentNode.position = SCNVector3(0.6,0,0)
        
        let moon = SCNSphere(radius: 0.025)
        let moonNode = createPlanetNode(geometry: moon, position: SCNVector3(0.15,0,0), diffuse: UIImage(named: "moon diffuse.jpg") , specular: nil, emission: nil, normal: nil)
        
        // node for venus, around the sun
        // let venus = SCNSphere(radius: 0.1)
        // let venusNode = createPlanetNode(geometry: venus, position: SCNVector3(0.6, 0, 0), diffuse: nil, specular: nil, emission: nil, normal: nil)
        self.sceneView.scene.rootNode.addChildNode(sunNode)
        self.sceneView.scene.rootNode.addChildNode(earthParentNode)
        self.sceneView.scene.rootNode.addChildNode(moonParentNode)
        
        
        earthParentNode.addChildNode(earthNode)
        earthParentNode.addChildNode(moonParentNode)
        moonParentNode.addChildNode(moonNode)
        
        
        let earthParentRotate = rotateWithTime(time: 14)
        let moonParentRotate = rotateWithTime(time:5)
        let sunRotate = rotateWithTime(time: 8)
        let earthRotate = rotateWithTime(time: 8)
        let moonRotate = rotateWithTime(time: 6)
        
        //apply planets rotation
        sunNode.runAction(sunRotate)
        earthNode.runAction(earthRotate)
        moonNode.runAction(moonRotate)
        
        //apply planets revolution
        earthParentNode.runAction(earthParentRotate)
        moonParentNode.runAction(moonParentRotate)
    }
    
    //add an aiming cross and set it to be at the middle of the screen
    func addAimingCrossButton(){
        plusButton = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        self.view?.addSubview(plusButton)

        let plusButtonImg = UIImage(named: "plus.png")
        plusButton.translatesAutoresizingMaskIntoConstraints = false


        plusButton.backgroundColor = nil
        plusButton.setImage(plusButtonImg, for: UIControl.State.normal)


        NSLayoutConstraint(item: plusButton, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0).isActive = true

        NSLayoutConstraint(item: plusButton, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0).isActive = true
    }
    
//    func addLabel(){
//        let planeIndiLabel = UILabel(frame: CGRect(x: 100, y: 100, width: 20, height: 10))
//        self.view?.addSubview(planeIndiLabel)
//
//        planeIndiLabel.text = "plane detected!"
//        planeIndiLabel.translatesAutoresizingMaskIntoConstraints = false
//
//        planeIndiLabel.backgroundColor = nil
//
//        NSLayoutConstraint(item: planeIndiLabel, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0).isActive = true
//
//
//
////        stackView.translatesAutoresizingMaskIntoConstraints = false
////
////        stackView.addConstraint(NSLayoutConstraint(item: stackView, attribute: .trailing, relatedBy: .equal, toItem: stackView, attribute: .trailing, multiplier: 1, constant: 0))
////        stackView.addConstraint(NSLayoutConstraint(item: stackView, attribute: .leading, relatedBy: .equal, toItem: stackView, attribute: .leading, multiplier: 1, constant: 0))
//
//        NSLayoutConstraint(item: planeIndiLabel, attribute: .top, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
////        stackView.addConstraint(NSLayoutConstraint(item: stackView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,multiplier: 1,
////                                                   constant: 131))
//
//    }
    
    private func setupLabels() {
        
        // setup the UI
        let size = sceneView.bounds
        
        groundNode = SKLabelNode(attributedText: NSAttributedString(string: "Ground is detected!", attributes: stringAttributes))
        groundNode.alpha = 1

        
        scoreNode = SKLabelNode(attributedText: NSAttributedString(string: "Enemies: \(game.totalUFOs - game.score)", attributes: stringAttributes))
        scoreNode.alpha = 1
        
        var i = 0
        var healthEmoji = ""
        while i<game.health {
            i = i+1
            healthEmoji += "♥️"
        }
        
        
        livesNode = SKLabelNode(attributedText: NSAttributedString(string: "Health: \(healthEmoji)", attributes: stringAttributes))
        livesNode.alpha = 1
        
        
        

        crosshair = SKSpriteNode(imageNamed: "plus.png")
        crosshair.size = CGSize(width: 25, height: 25)
        crosshair.alpha = 1
        
        groundNode.position = CGPoint(x: sidePadding + livesNode.frame.width + 90, y: 40 + sidePadding)
        groundNode.horizontalAlignmentMode = .center
        
        scoreNode.position = CGPoint(x: sidePadding + livesNode.frame.width + 80, y: 30 + sidePadding)
        scoreNode.horizontalAlignmentMode = .center
        livesNode.position = CGPoint(x: sidePadding, y: 30 + sidePadding)
        livesNode.horizontalAlignmentMode = .left
        crosshair.position = CGPoint(x: size.midX, y: size.midY)
        
        sceneView.overlaySKScene?.addChild(scoreNode)
        sceneView.overlaySKScene?.addChild(livesNode)
        sceneView.overlaySKScene?.addChild(crosshair)
        sceneView.overlaySKScene?.addChild(groundNode)
    }
    
    
    //create a new node with an planet attached, with geometry, position, and materials
    func createPlanetNode(geometry: SCNGeometry, position: SCNVector3, diffuse: UIImage?, specular: UIImage?, emission: UIImage?, normal: UIImage?) -> SCNNode {
        let newPlanet = SCNNode(geometry: geometry)
        newPlanet.position = position
        newPlanet.geometry?.firstMaterial?.diffuse.contents = diffuse
        newPlanet.geometry?.firstMaterial?.specular.contents = specular
        newPlanet.geometry?.firstMaterial?.emission.contents = emission
        newPlanet.geometry?.firstMaterial?.normal.contents = normal
        return newPlanet
    }
    
    //create an SCNAction to let the planet rotate, input time/cycle
    func rotateWithTime(time: TimeInterval) -> SCNAction {
        let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: time)
        let rotateForeverAct = SCNAction.repeatForever(rotateAction)
        return rotateForeverAct
    }
    
    
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        if !hitTestResult.isEmpty && game.portalCreated == nil {
            self.addPortal(hitTestResult: hitTestResult.first!)
        } else {
            ////
        }

        
        
        if(game.playerCanShoot()){
//            guard let sceneView = sender.view as? ARSCNView else {return}
            guard let pointOfView = sceneView.pointOfView else {return}
//            let transform = pointOfView.transform
//            let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
//            let location = SCNVector3(transform.m41, transform.m42, transform.m43)
//            let position = orientation + location
//            let bullet = SCNNode(geometry: SCNSphere(radius: 0.1))
//            bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.red
//            bullet.position = position
//            //let body = SCNPhysicsBody(type: .static, shape: )
//            let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: bullet, options: nil))
//            body.isAffectedByGravity = false
//            bullet.physicsBody = body
//            bullet.physicsBody?.categoryBitMask = PhysicsMask.playerBullet
//            bullet.physicsBody?.contactTestBitMask = PhysicsMask.enemy
            
            fireLaser(fromNode: pointOfView, type: .player)
        
            //self.sceneView.scene.rootNode.addChildNode(bullet)

//            bullet.runAction(
//                SCNAction.sequence([SCNAction.wait(duration: 2.0),
//                                    SCNAction.removeFromParentNode()])
//            )
            
        }
    }
    
    func fireLaser(fromNode node: SCNNode, type: LaserType){
        guard game.winLoseFlag == nil else { return }
        let pov = sceneView.pointOfView!
        var position: SCNVector3
        var convertedPosition: SCNVector3
        var direction : SCNVector3
        switch type {
            
        case .enemy:
            // If enemy, shoot at the player
            position = SCNVector3Make(0, 0, 0.05)
            convertedPosition = node.convertPosition(position, to: nil)
            direction = pov.position - node.position
        default:
            // play the sound effect
            //self.playSoundEffect(ofType: .torpedo)
            // if player, shoot straight ahead
            position = SCNVector3Make(0, 0, -0.05)
            convertedPosition = node.convertPosition(position, to: nil)
            direction = convertedPosition - pov.position
        }
        
        let laser = LaserNode(initialPosition: convertedPosition, direction: direction, type: type)
        lasers.append(laser)
        sceneView.scene.rootNode.addChildNode(laser.node)
    }
    
    
    func animateUFOWhenHit(node: SCNNode) {
        let spin = CABasicAnimation(keyPath: "position")
        spin.fromValue = node.presentation.position
        spin.toValue = SCNVector3(node.presentation.position.x - 0.2 ,node.presentation.position.y - 0.2, node.presentation.position.z - 0.2)
        spin.duration = 0.07
        spin.repeatCount = 5
        spin.autoreverses = true
        node.addAnimation(spin, forKey: "postion")
    }
    

    func addTargets() {
        self.addUFO(x: 0.5, y: 0, z: 0.5)
        self.addUFO(x: 0, y: 0, z: 0.5)
        self.addUFO(x: -0.5, y: 0, z: 0.5)
    }

//
    func addUFO(x: Float, y: Float, z: Float) {
        let UFOScene = SCNScene(named: "nave.scn")
        let UFONode = (UFOScene?.rootNode.childNode(withName: "Sphere", recursively: true))!
        UFONode.position = SCNVector3(x,y,z)
        UFONode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: UFONode, options: nil))
//        UFONode.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
//        UFONode.physicsBody?.contactTestBitMask = BitMaskCategory.bullet.rawValue
//        UFONode.physicsBody?.collisionBitMask = BitMaskCategory.bullet.rawValue
        UFONode.physicsBody?.categoryBitMask = PhysicsMask.enemy
        UFONode.physicsBody?.contactTestBitMask = PhysicsMask.playerBullet
        UFONode.physicsBody?.isAffectedByGravity = false
        sceneView.scene.rootNode.addChildNode(UFONode)
    }
    
    
//    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
//        let nodeA = contact.nodeA
//        let nodeB = contact.nodeB
//
//        if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
//            self.Target = nodeA
//            print("========213 test=========")
//        } else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
//            self.Target = nodeB
//            print("========216 test=========")
//        }
//        let confetti = SCNParticleSystem(named: "fire", inDirectory: "/")
//        confetti?.loops = false
//        confetti?.particleLifeSpan = 4
//        confetti?.emitterShape = Target?.geometry
//        let confettiNode = SCNNode()
//        confettiNode.addParticleSystem(confetti!)
//        confettiNode.position = contact.contactPoint
//        self.sceneView.scene.rootNode.addChildNode(confettiNode)
//        Target?.removeFromParentNode()
//    }
    
//    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
//        let maskA = contact.nodeA.physicsBody!.contactTestBitMask
//        let maskB = contact.nodeB.physicsBody!.contactTestBitMask
//
//        switch(maskA, maskB){
//        case (PhysicsMask.enemy, PhysicsMask.playerBullet):
//            //self.playSoundEffect(ofType: .collision)
//            hitEnemy(bullet: contact.nodeB, enemy: contact.nodeA)
//            //self.playSoundEffect(ofType: .collision)
//        case (PhysicsMask.playerBullet, PhysicsMask.enemy):
//            //self.playSoundEffect(ofType: .collision)
//            hitEnemy(bullet: contact.nodeA, enemy: contact.nodeB)
//        default:
//            break
//        }
//    }
    
    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let maskA = contact.nodeA.physicsBody!.contactTestBitMask
        let maskB = contact.nodeB.physicsBody!.contactTestBitMask
        
        switch(maskA, maskB) {
        case (PhysicsMask.enemy, PhysicsMask.playerBullet) :
            hitEnemy(bullet: contact.nodeA, enemy: contact.nodeB)
        
        case (PhysicsMask.playerBullet, PhysicsMask.enemy) :
            hitEnemy(bullet: contact.nodeB, enemy: contact.nodeA)
            
        default:
            break
        }
        
    }
    
    func hitEnemy(bullet: SCNNode, enemy: SCNNode){
        let fire = SCNParticleSystem(named: "fire", inDirectory: "/")
        fire?.loops = false
        fire?.particleLifeSpan = 4
        fire?.emitterShape = enemy.geometry
        
        let fireNode = SCNNode()
        fireNode.addParticleSystem(fire!)
        //fireNode.scale = SCNVector3(x: 0.005, y: 0.005, z: 0.005)
        fireNode.position = enemy.position
        sceneView.scene.rootNode.addChildNode(fireNode)
        
        bullet.removeFromParentNode()
        enemy.removeFromParentNode()
        game.score += 1
    }
    
    
    private func showFinish() {
        guard let hasWon = game.winLoseFlag else { return }
        // present the AR text
        let text = SCNText(string: hasWon ? "You Saved The Day! Onward to WWDC!" : "Aww, Try Again!", extrusionDepth: 0.5)
        let material = SCNMaterial()
        material.diffuse.contents = hasWon ? UIColor.green : UIColor.red
        
        // make the text appear on multiple lines
        text.isWrapped = true
        text.containerFrame = CGRect(origin: .zero, size: CGSize(width: 100.0, height: 400.0))
        text.materials = [material]
        
        let node = SCNNode()
        node.simdPosition = simd_float3((sceneView.pointOfView?.simdPosition.x)!, (sceneView.pointOfView?.simdPosition.y)! - 2.8, (sceneView.pointOfView?.simdPosition.z)!) + sceneView.pointOfView!.simdWorldFront * 0.5
        node.simdRotation = sceneView.pointOfView!.simdRotation
        node.scale = SCNVector3(x: 0.007, y: 0.007, z: 0.007)
        node.geometry = text
        
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    
    private func spawnUFO(UFO: UFO){
        let pov = sceneView.pointOfView!
        let y = (Float(arc4random_uniform(60)) - 29) * 0.01 // Random Y value between -0.3 and 0.3
        
        //Random X and Z values for the UFO
        let xRad = ((Float(arc4random_uniform(361)) - 180)/180) * Float.pi
        let zRad = ((Float(arc4random_uniform(361)) - 180)/180) * Float.pi
        let length = Float(arc4random_uniform(6) + 4) * -0.3
        let x = length * sin(xRad)
        let z = length * cos(zRad)
        let position = SCNVector3Make(x, y, z)
        let worldPosition = pov.convertPosition(position, to: nil)
        let UFONode1 = UFONode(UFO: UFO, position: worldPosition, cameraPosition: pov.position)
        
        UFOs.append(UFONode1)
        sceneView.scene.rootNode.addChildNode(UFONode1.node)
    }
    
    
}


//func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
//    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
//}

//MARK: AR SceneView Delegate
extension ViewController {
    
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.groundNode.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+4) {
            self.groundNode.isHidden = true
        }
    }
    
    
    
    
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        guard game.gameStart != nil else {return}
        
        guard game.winLoseFlag == nil else { return }
        
        // Let Game spawn an UFO
        if let UFO = game.spawnUFO(numUFOs: UFOs.count) {
            spawnUFO(UFO: UFO)
        }
        
        for (i, UFO) in UFOs.enumerated().reversed() {
            
            // If the UFO no longer exists, remove it from the list
            guard UFO.node.parent != nil else {
                UFOs.remove(at: i)
                continue
            }
            
            // move the UFO towards to player
            if UFO.move(towardsPosition: sceneView.pointOfView!.position) == false {
                // if the UFO can't move closer, it crashes into the player
                UFO.node.removeFromParentNode()
                UFOs.remove(at: i)
                game.health -= UFO.UFO.health
            }else {
                if UFO.UFO.shouldShoot() {
                    fireLaser(fromNode: UFO.node, type: .enemy)
                }
            }
        }
        
//        // Draw UFOs on the radar as an XZ Plane
//        for (i, blip) in radarNode.children.enumerated() {
//            if i < UFOs.count {
//                let UFO = UFOs[i]
//                blip.alpha = 1
//                let relativePosition = sceneView.pointOfView!.convertPosition(UFO.node.position, from: nil)
//                var x = relativePosition.x * 10
//                var y = relativePosition.z * -10
//                if x >= 0 { x = min(x, 35) } else { x = max(x, -35)}
//                if y >= 0 { y = min(y, 35) } else { y = max(y, -35)}
//                blip.position = CGPoint(x: CGFloat(x), y: CGFloat(y))
//            }else{
//                // If the UFO hasn't spawned yet, hide the blip
//                blip.alpha = 0
//            }
//
//        }
        
        for (i, laser) in lasers.enumerated().reversed() {
            if laser.node.parent == nil {
                // If the bullet no longer exists, remove it from the list
                lasers.remove(at: i)
            }
            // move the laser
            if laser.move() == false {
                laser.node.removeFromParentNode()
                lasers.remove(at: i)
            } else {
                // Check if the bullet hit the player
                if laser.node.physicsBody?.contactTestBitMask == PhysicsMask.player
                    && laser.node.position.distance(vector: sceneView.pointOfView!.position) < 0.03{
                    laser.node.removeFromParentNode()
                    lasers.remove(at: i)
                    game.health -= 1
                }
            }
        }
    }
    
}



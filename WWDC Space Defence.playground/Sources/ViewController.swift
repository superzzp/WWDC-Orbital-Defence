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
    var UFOs = [UFONode]()
    var lasers = [LaserNode]()
    var portalPosition = SCNVector3(x: 0, y: 0, z: 0)
    
    //Timer
    var clockUpdateTime: TimeInterval = 0
    
    //UI
    var groundNode : SKLabelNode!
    var scoreNode : SKLabelNode!
    var livesNode : SKLabelNode!
    var timerNode : SKLabelNode!
    var plusButton: UIButton!
    let sidePadding : CGFloat = 5

    //Unified Font
    lazy var paragraphStyle : NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.left
        return style
    }()
    
    lazy var stringAttributes : [NSAttributedString.Key : Any] = [.strokeColor : UIColor.black, .strokeWidth : -4, .foregroundColor: UIColor.white, .font : UIFont.systemFont(ofSize: 23, weight: .bold), .paragraphStyle : paragraphStyle]
    
    var bulletSpeed: Float = 50
    let session = ARSession()
    public var game = Game()
    public var animation = Animation()
    
    
    //GameDelegate Functions
    func scoreDidChange() {
        scoreNode.attributedText = NSMutableAttributedString(string: "Scores: \(game.score)", attributes: stringAttributes)
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
        
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        
        
        
        self.sceneView.session.run(configuration)
        
        sceneView.scene.physicsWorld.contactDelegate = self
        
        //setup overlay
        sceneView.overlaySKScene = SKScene(size: sceneView.bounds.size)
        sceneView.overlaySKScene?.scaleMode = .resizeFill
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        //Setup labels
        setupLabels()

        hideAllGameLabels()
    }
    
    private func setupLabels() {
        
        // setup the UI
        addAimingCrossButton()
        
        groundNode = SKLabelNode(attributedText: NSAttributedString(string: "Ground is detected!", attributes: stringAttributes))
        groundNode.alpha = 1
        
        
        scoreNode = SKLabelNode(attributedText: NSAttributedString(string: "Scores: \(game.score)", attributes: stringAttributes))
        scoreNode.alpha = 1
        
        var i = 0
        var healthEmoji = ""
        while i<game.health {
            i = i+1
            healthEmoji += "♥️"
        }
        
        
        livesNode = SKLabelNode(attributedText: NSAttributedString(string: "Health: \(healthEmoji)", attributes: stringAttributes))
        livesNode.alpha = 1
        
        timerNode = SKLabelNode(attributedText: NSAttributedString(string: "Time Remain: \(game.gameDuration)", attributes: stringAttributes))
        timerNode.alpha = 1
        
        
        groundNode.position = CGPoint(x: sidePadding + livesNode.frame.width + 10, y: 80 + sidePadding)
        
        groundNode.horizontalAlignmentMode = .center
        
        scoreNode.position = CGPoint(x: sidePadding + livesNode.frame.width + 80, y: 30 + sidePadding)
        scoreNode.horizontalAlignmentMode = .center
        
        livesNode.position = CGPoint(x: sidePadding, y: 30 + sidePadding)
        livesNode.horizontalAlignmentMode = .left
        
        timerNode.position = CGPoint(x: sidePadding + livesNode.frame.width + 60, y: 70 + sidePadding)
        timerNode.horizontalAlignmentMode = .center
        
        sceneView.overlaySKScene?.addChild(scoreNode)
        sceneView.overlaySKScene?.addChild(livesNode)
        sceneView.overlaySKScene?.addChild(groundNode)
        sceneView.overlaySKScene?.addChild(timerNode)
    }
    
    
    // helper function for setupLabels(), add an aiming cross and set it to be at the middle of the screen
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
    
    
    //helper function for setupLabels(), hide all game labels before game starts
    func hideAllGameLabels() {
        scoreNode.isHidden = true
        livesNode.isHidden = true
        plusButton.isHidden = true
        timerNode.isHidden = true
    }
    
    //helper function for setupLabels(), display all game labels after game starts
    func displayAllGameLabels() {
        scoreNode.isHidden = false
        livesNode.isHidden = false
        plusButton.isHidden = false
        timerNode.isHidden = false
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
        
        let portalRotate = SCNAction.rotateBy(x: 0, y: CGFloat(180.degreesToRadians), z: 0, duration: 0)
        portalNode.runAction(portalRotate)
        portalNode.name = "portal"
        
        self.sceneView.scene.rootNode.addChildNode(portalNode)
        self.addPlane(nodeName: "roof", portalNode: portalNode, imageName: "top")
        self.addPlane(nodeName: "floor", portalNode: portalNode, imageName: "bottom")
        self.addWalls(nodeName: "backWall", portalNode: portalNode, imageName: "back")
        self.addWalls(nodeName: "sideWallA", portalNode: portalNode, imageName: "sideA")
        self.addWalls(nodeName: "sideWallB", portalNode: portalNode, imageName: "sideB")
        self.addWalls(nodeName: "sideDoorA", portalNode: portalNode, imageName: "sideDoorA")
        self.addWalls(nodeName: "sideDoorB", portalNode: portalNode, imageName: "sideDoorB")
        
        let pathway = portalNode.childNode(withName: "StargatePathway", recursively: false)
        animation.animatePathwayOpacity(node: pathway!)
        
        self.game.hasPortal = true
    
        
    }
    
    //Helper function for addPortal(), add walls for the portal
    //set the mask to be transparent, and set the wall behind it to render after the mask,
    //so both mask and walls will be transparent
    func addWalls(nodeName: String, portalNode: SCNNode, imageName: String) {
        let child = portalNode.childNode(withName: nodeName, recursively: true)
        child?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "\(imageName).png")
        child?.renderingOrder = 200
        if let mask = child?.childNode(withName: "mask", recursively: false) {
            mask.geometry?.firstMaterial?.transparency = 0.000001
        }
    }
    
    // Helper function for addPortal(), add floor and ceiling for the portal
    func addPlane(nodeName: String, portalNode: SCNNode, imageName: String) {
        let child = portalNode.childNode(withName: nodeName, recursively: true)
        child?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "\(imageName).png")
        child?.renderingOrder = 200
    }
    
    // Create the universe and planet nodes, and apply rotation and revolution
    func createUniverse(centerPos: SCNVector3){
        let sun = SCNSphere(radius: 0.35)
        let sunNode = createPlanetNode(geometry: sun, position: centerPos, diffuse: UIImage.init(named: "sun diffuse.jpg") , specular: nil, emission: nil, normal: nil)
        sunNode.addParticleSystem(SCNParticleSystem(named: "sparksParticle", inDirectory: "/")!)
        
        
        let earthParentNode = SCNNode()
        earthParentNode.position = centerPos
        
        let jupiterParentNode = SCNNode()
        jupiterParentNode.position = centerPos
        
        let saturnParentNode = SCNNode()
        saturnParentNode.position = centerPos
        
        //node for earth, rotate around the sun
        let earth = SCNSphere(radius: 0.08)
        let earthNode = createPlanetNode(geometry: earth, position: SCNVector3(1.2,0,0), diffuse: UIImage.init(named: "earth diffuse.jpg") , specular: UIImage.init(named: "earth specular"), emission: UIImage.init(named: "earth emission"), normal: UIImage.init(named: "earth normal"))
        
        //node for moon, rotate around the earth
        let moonParentNode = SCNNode()
        moonParentNode.position = SCNVector3(1.2,0,0)
        
        let moon = SCNSphere(radius: 0.04)
        let moonNode = createPlanetNode(geometry: moon, position: SCNVector3(0.3,0,0), diffuse: UIImage(named: "moon diffuse.jpg") , specular: nil, emission: nil, normal: nil)
        
        // node for Jupiter, rotate around the sun
        // please bring me luck Jupiter
        let jupiter = SCNSphere(radius: 0.14)
        let jupiterNode = createPlanetNode(geometry: jupiter, position: SCNVector3(0, 0, 1.5), diffuse: UIImage(named: "jupiter diffuse.jpg"), specular: nil, emission: nil, normal: nil)
        
        // node for Saturn, rotate around the sun
        // attach a ring node with saturn
        let saturn = SCNSphere(radius: 0.13)
        let saturnNode = createPlanetNode(geometry: saturn, position: SCNVector3(2.0, 0, 0), diffuse: UIImage(named: "saturn diffuse.jpg"), specular: nil, emission: nil, normal: nil)
        
        let loopNode = SCNNode(geometry: SCNBox(width: 0.52, height: 0.65, length: 0, chamferRadius: 0))
        loopNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "saturn ring.png")
        loopNode.rotation = SCNVector4(-0.5, -0.05, 0, 5)
        saturnNode.addChildNode(loopNode)
        
        self.sceneView.scene.rootNode.addChildNode(sunNode)
        self.sceneView.scene.rootNode.addChildNode(earthParentNode)
        self.sceneView.scene.rootNode.addChildNode(moonParentNode)
        self.sceneView.scene.rootNode.addChildNode(jupiterParentNode)
        self.sceneView.scene.rootNode.addChildNode(saturnParentNode)
        
        earthParentNode.addChildNode(earthNode)
        earthParentNode.addChildNode(moonParentNode)
        moonParentNode.addChildNode(moonNode)
        jupiterParentNode.addChildNode(jupiterNode)
        saturnParentNode.addChildNode(saturnNode)
        
        let earthParentRotate = rotateWithTime(time: 28)
        let moonParentRotate = rotateWithTime(time:15)
        let jupiterParentRotate = rotateWithTime(time: 34)
        let saturnParentRotate = rotateWithTime(time: 30)
        
        let sunRotate = rotateWithTime(time: 24)
        let earthRotate = rotateWithTime(time: 24)
        let moonRotate = rotateWithTime(time: 18)
        let jupiterRotate = rotateWithTime(time: 24)
        let saturnRotate = rotateWithTime(time: 24)
        
        //apply planets rotation
        sunNode.runAction(sunRotate)
        earthNode.runAction(earthRotate)
        moonNode.runAction(moonRotate)
        jupiterNode.runAction(jupiterRotate)
        saturnNode.runAction(saturnRotate)
        
        //apply planets revolution
        earthParentNode.runAction(earthParentRotate)
        moonParentNode.runAction(moonParentRotate)
        jupiterParentNode.runAction(jupiterParentRotate)
        saturnParentNode.runAction(saturnParentRotate)
        
    }
    
    // Create a new node with an planet attached, with geometry, position, and materials
    func createPlanetNode(geometry: SCNGeometry, position: SCNVector3, diffuse: UIImage?, specular: UIImage?, emission: UIImage?, normal: UIImage?) -> SCNNode {
        let newPlanet = SCNNode(geometry: geometry)
        newPlanet.position = position
        newPlanet.geometry?.firstMaterial?.diffuse.contents = diffuse
        newPlanet.geometry?.firstMaterial?.specular.contents = specular
        newPlanet.geometry?.firstMaterial?.emission.contents = emission
        newPlanet.geometry?.firstMaterial?.normal.contents = normal
        return newPlanet
    }
    
    // Create an SCNAction to let the planet rotate, with input of time per cycle
    func rotateWithTime(time: TimeInterval) -> SCNAction {
        let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: time)
        let rotateForeverAct = SCNAction.repeatForever(rotateAction)
        return rotateForeverAct
    }

    // If player tap on ground, first create a portal
    // If player can shoot, shoot bullet
    @objc func handleTap(sender: UITapGestureRecognizer) {
        
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        if !hitTestResult.isEmpty && game.hasPortal == nil {
            self.addPortal(hitTestResult: hitTestResult.first!)
        }
        
        if(game.playerCanShoot()){
            guard let pointOfView = sceneView.pointOfView else {return}
            fireLaser(fromNode: pointOfView, type: .player)
            
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
            // if player, shoot straight ahead
            position = SCNVector3Make(0, 0, -0.05)
            convertedPosition = node.convertPosition(position, to: nil)
            direction = convertedPosition - pov.position
        }
        
        let laser = LaserNode(initialPosition: convertedPosition, direction: direction, type: type)
        lasers.append(laser)
        sceneView.scene.rootNode.addChildNode(laser.node)
    }
    
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

    // Apply animation and explosion particle to enemy node when hit
    // Remove enemy and bullet from scene after animation is complete
    func hitEnemy(bullet: SCNNode, enemy: SCNNode) {
        // If enemy currently have no animation, continue
        // So only one animations be applied to a node at a time
        if (enemy.animationKeys.isEmpty) {
            SCNTransaction.begin()
            animation.animateUFOWhenHit(node: enemy)
            SCNTransaction.completionBlock = {
                let fire = SCNParticleSystem(named: "fire", inDirectory: "/")
                fire?.loops = false
                fire?.particleLifeSpan = 4
                fire?.emitterShape = enemy.geometry
                
                let fireNode = SCNNode()
                fireNode.addParticleSystem(fire!)
                fireNode.scale = SCNVector3(x: 0.005, y: 0.005, z: 0.005)
                fireNode.position = bullet.position
                self.sceneView.scene.rootNode.addChildNode(fireNode)
                
                bullet.removeFromParentNode()
                enemy.removeFromParentNode()
                self.game.score += 1
            }
            SCNTransaction.commit()
        }
    }
    
    
    private func showFinish() {
        guard let hasWon = game.winLoseFlag else { return }
        // present the AR text
        let text = SCNText(string: hasWon ? "You Saved The Universe! Onward to SWDC!" : "Yikes...Try Again!", extrusionDepth: 0.5)
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

//AR SceneView Delegate
extension ViewController {
    
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if (game.hasPortal == nil) {
            guard anchor is ARPlaneAnchor else {return}
            DispatchQueue.main.async {
                self.groundNode.attributedText = NSMutableAttributedString(string: "Ground Detected! Tap on it to create Stargate!", attributes: self.stringAttributes)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.groundNode.attributedText = NSMutableAttributedString(string: "Tap On Ground To Create Stargate!", attributes: self.stringAttributes)
            }
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        // Return until player create a portal
        guard game.hasPortal != nil else {return}
        
        // Guide player to walk into the portal after its creation
        if (game.gameStart == nil) {
            DispatchQueue.main.async {
                self.groundNode.attributedText = NSMutableAttributedString(string: "Walk in Stargate to start the game!", attributes: self.stringAttributes)
            }
        }
        
        // After player walk into the portal, start the game
        if ((game.gameStart == nil) && (sceneView.pointOfView!.position.z >= portalPosition.z + 1.5)) {
            self.game.gameStart = true
            groundNode.isHidden = true
            displayAllGameLabels()
            var portalNode = sceneView.scene.rootNode.childNode(withName: "portal", recursively: true)
            
            // Pull the player into the universe by moving portal forward
            SCNTransaction.begin()
            animation.animatePortalMovement(node: portalNode!)
            SCNTransaction.completionBlock = {
                portalNode = self.sceneView.scene.rootNode.childNode(withName: "portal", recursively: true)
                self.portalPosition = portalNode!.position
                
                //set the center of the universe to be the center of the portal scene
                let universeCenterPosition = SCNVector3Make(self.portalPosition.x, self.portalPosition.y + 1.5, self.portalPosition.z + 4.0)
                
                //create the universe
                self.createUniverse(centerPos: universeCenterPosition)
                
                //add stars particle to the universe
                let starsParticle = SCNParticleSystem(named: "starsParticle", inDirectory: "/")
                let starsNode = SCNNode()
                starsNode.position = universeCenterPosition
                starsNode.addParticleSystem(starsParticle!)
                
            }
            SCNTransaction.commit()
        }
        
        guard game.gameStart != nil else {return}
        
        guard game.winLoseFlag == nil else { return }
        
        // Update the time indicator
        // Player win the game after holding for 60 seconds
        if(time > clockUpdateTime) {
            //schedule the clockUpdateTime when system time is forward
            clockUpdateTime = time + TimeInterval(1)
            
            game.gameDuration -= 1
            DispatchQueue.main.async {
                self.timerNode.attributedText = NSMutableAttributedString(string: "Time Remaining: \(self.game.gameDuration)", attributes: self.stringAttributes)
            }
            if(game.gameDuration == 0) {
                game.winLoseFlag = true
                showFinish()
            }
            
        }
        
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



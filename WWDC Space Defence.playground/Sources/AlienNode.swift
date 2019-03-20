

import ARKit
import UIKit

public class AlienNode : SCNNodeContainer{
    
    var node : SCNNode!
    var alien : Alien
    var lastAxis = SCNVector3Make(0, 0, 0)
    
    var spawnCount = 0
    
    // setup initial alien values
    init(alien: Alien, position: SCNVector3, cameraPosition: SCNVector3) {

        self.alien = alien
        self.node = createNode()
        self.node.position = position
        self.node.rotation = SCNVector4Make(0, 1, 0, 0)
        
        let deltaRotation = getXZRotation(towardsPosition: cameraPosition)
        if deltaRotation > 0 {
            node.rotation.w -= deltaRotation
        }else if deltaRotation < 0 {
            node.rotation.w -= deltaRotation
        }
    }
    
    // returns what angle the alien has to rotate to face the given position
    func getXZRotation(towardsPosition toPosition: SCNVector3) -> Float {
        
        // creates the normalized vector for the position
        var unitDistance = (toPosition - node.position).negate()
        unitDistance.y = 0
        unitDistance = unitDistance.normalized()
        
        // creates the normalized vector for the alien
        var unitDirection = self.node.convertPosition(SCNVector3Make(0, 0, -1), to: nil) - self.node.position
        unitDirection.y = 0
        unitDirection = unitDirection.normalized()
        
        // returns the angle it has to rotate
        let axis = unitDistance.cross(vector: unitDirection).normalized() //cross product
        let angle = acos(unitDistance.dot(vector: unitDirection))
        return angle * axis.y
        
    }
    
    private func createNode() -> SCNNode{
        let UFOScene = SCNScene(named: "nave.scn")
        let UFONode = (UFOScene?.rootNode.childNode(withName: "Sphere", recursively: true))!
        UFONode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: UFONode, options: nil))
//      static physics body so movement can be controlled manually
//        UFONode.physicsBody?.categoryBitMask = PhysicsMask.enemy
//        UFONode.physicsBody?.contactTestBitMask = PhysicsMask.playerBullet
        UFONode.physicsBody?.categoryBitMask = PhysicsMask.enemy
        UFONode.physicsBody?.contactTestBitMask = PhysicsMask.playerBullet
        UFONode.physicsBody?.isAffectedByGravity = false
        return UFONode
    }
    
    func move(towardsPosition toPosition : SCNVector3) -> Bool{
        
        // distance between alien and the position
        let deltaPos = (toPosition - node.position)
        
        // if alien is too close to move, it won't
        guard deltaPos.length() > 0.05 else { return false }
        let normDeltaPos = deltaPos.normalized()
        
        // move the Y so its closer to the player
        node.position.y += normDeltaPos.y/50

        // distance on XZ plane
        let length = deltaPos.xzLength()
        
        // if alien is not in the "goldilocks zone", move towards the player
        // if alien is really close to the player, it crashes into the player
        if length > 0.5 || length < 0.1 {
            node.position.x += normDeltaPos.x/250
            node.position.z += normDeltaPos.z/250
            alien.closeQuarters = false
        }else{
            alien.closeQuarters = true
        }
        
        // angle it must rotate to face player
        let goalRotation = getXZRotation(towardsPosition: toPosition)
        
        // slowly rotate in that direction
        if goalRotation > 0 {
            node.rotation.w -= min(Float.pi/180, goalRotation)
        }else if goalRotation < 0 {
            node.rotation.w -= max(-Float.pi/180, goalRotation)
        }
        
        return true
    }
    
    
}
